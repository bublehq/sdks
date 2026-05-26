# frozen_string_literal: true

require 'cgi/escape'
require 'json'
require 'net/http'
require 'openssl'
require 'uri'

module Buble
  class HTTP
    DEFAULT_BASE_URL = 'https://buble.ai'
    DEFAULT_TIMEOUT = 60

    FilePart = Struct.new(:io, :filename, :content_type, :close_after, keyword_init: true) do
      def close
        io.close if close_after && io.respond_to?(:close) && !io.closed?
      end
    end

    def initialize(api_key:, base_url: DEFAULT_BASE_URL, timeout: DEFAULT_TIMEOUT, headers: {})
      raise Error, 'Missing Buble API key. Pass api_key or set BUBLE_API_KEY.' if blank?(api_key)

      @api_key = api_key
      @base_url = base_url.to_s.sub(%r{/+\z}, '')
      @timeout = timeout
      @headers = stringify_hash(headers)
    end

    def request(method, path, query: nil, body: nil, headers: nil, timeout: nil)
      response = perform(method, path, query: query, body: body, headers: headers, timeout: timeout)
      decode_response(response)
    end

    def multipart(path, fields:, file:, query: nil, headers: nil, timeout: nil)
      part = coerce_file_part(file)
      request = Net::HTTP::Post.new(resolve(path, query))
      request_headers(headers).each { |name, value| request[name] = value }
      request['Accept'] = 'application/json'

      form = stringify_hash(fields).reject { |_key, value| value.nil? || value == '' }.map do |key, value|
        [key, value.to_s]
      end
      form << ['file', part.io, { filename: part.filename, content_type: part.content_type }]
      request.set_form(form, 'multipart/form-data')

      response = start_http(request.uri, timeout || @timeout) { |http| http.request(request) }
      decode_response(response)
    ensure
      part&.close
    end

    def stream_lines(method, path, query: nil, body: nil, headers: nil, timeout: nil)
      Enumerator.new do |yielder|
        request = build_request(method, path, query: query, body: body, headers: {
          'Accept' => 'text/event-stream'
        }.merge(stringify_hash(headers || {})))

        buffer = +''
        start_http(request.uri, timeout || @timeout) do |http|
          http.request(request) do |response|
            raise api_error(response) unless success?(response)

            response.read_body do |chunk|
              buffer << chunk
              while (index = buffer.index("\n"))
                line = buffer.slice!(0..index)
                yielder << line.chomp
              end
            end
          end
        end
        yielder << buffer unless buffer.empty?
      end
    end

    def self.encode_segment(value)
      CGI.escape(value.to_s).gsub('+', '%20')
    end

    def self.encode_model_path(value)
      value.to_s.split('/').map { |segment| encode_segment(segment) }.join('/')
    end

    private

    def perform(method, path, query:, body:, headers:, timeout:)
      request = build_request(method, path, query: query, body: body, headers: headers)
      start_http(request.uri, timeout || @timeout) { |http| http.request(request) }
    end

    def build_request(method, path, query:, body:, headers:)
      uri = resolve(path, query)
      request_class = request_class_for(method)
      request = request_class.new(uri)
      request_headers(headers).each { |name, value| request[name] = value }

      unless body.nil?
        request['Content-Type'] = 'application/json'
        request.body = JSON.generate(body)
      end

      request
    end

    def start_http(uri, timeout, &)
      Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == 'https',
        open_timeout: timeout,
        read_timeout: timeout, &
      )
    rescue Net::OpenTimeout, Net::ReadTimeout
      raise TimeoutError.new("Buble API request timed out after #{timeout} seconds.", timeout: timeout)
    end

    def resolve(path, query)
      normalized = path.start_with?('/') ? path : "/#{path}"
      uri = URI.parse("#{@base_url}#{normalized}")
      query_hash = stringify_hash(query || {}).compact
      uri.query = URI.encode_www_form(query_hash) unless query_hash.empty?
      uri
    end

    def request_headers(extra)
      {
        'Authorization' => "Bearer #{@api_key}",
        'Accept' => 'application/json'
      }.merge(@headers).merge(stringify_hash(extra || {}))
    end

    def request_class_for(method)
      case method.to_s.upcase
      when 'GET' then Net::HTTP::Get
      when 'POST' then Net::HTTP::Post
      when 'PUT' then Net::HTTP::Put
      when 'PATCH' then Net::HTTP::Patch
      when 'DELETE' then Net::HTTP::Delete
      else
        raise Error, "Unsupported HTTP method: #{method}"
      end
    end

    def decode_response(response)
      raise api_error(response) unless success?(response)
      return {} if response.body.nil? || response.body.empty?

      content_type = response['content-type'].to_s
      return JSON.parse(response.body) if content_type.include?('application/json')

      response.body
    rescue JSON::ParserError => e
      raise Error, "Failed to parse Buble API response: #{e.message}"
    end

    def api_error(response)
      body = response.body.to_s
      message = body.empty? ? "Buble API request failed with status #{response.code}." : body
      code = nil
      details = nil

      begin
        decoded = body.empty? ? nil : JSON.parse(body)
        error = decoded.is_a?(Hash) ? decoded['error'] : nil
        if error.is_a?(Hash)
          message = error['message'] || message
          code = error['code']
          details = error['details']
        end
      rescue JSON::ParserError
        # Keep the raw response body as the message.
      end

      APIError.new(message, status: response.code.to_i, code: code, details: details, response_body: body)
    end

    def success?(response)
      response.code.to_i >= 200 && response.code.to_i < 300
    end

    def coerce_file_part(file)
      return file if file.is_a?(FilePart)

      if file.is_a?(String)
        # The multipart request owns and closes this handle after Net::HTTP consumes it.
        # rubocop:disable Style/FileOpen
        io = File.open(file, 'rb')
        # rubocop:enable Style/FileOpen
        return FilePart.new(
          io: io,
          filename: File.basename(file),
          content_type: 'application/octet-stream',
          close_after: true
        )
      end

      if file.respond_to?(:read)
        filename = file.respond_to?(:path) && file.path ? File.basename(file.path) : 'upload'
        return FilePart.new(io: file, filename: filename, content_type: 'application/octet-stream', close_after: false)
      end

      raise Error, 'file must be a path, IO, or Buble::HTTP::FilePart.'
    end

    def stringify_hash(hash)
      hash.each_with_object({}) { |(key, value), out| out[key.to_s] = value }
    end

    def blank?(value)
      value.nil? || value.to_s.strip.empty?
    end
  end
end
