# frozen_string_literal: true

class FakeTransport
  attr_reader :requests

  def initialize
    @requests = []
    @responses = []
    @stream_lines = []
  end

  def enqueue_response(response)
    @responses << response
  end

  def enqueue_stream_lines(lines)
    @stream_lines << lines
  end

  def request(method, path, query: nil, body: nil, headers: nil, timeout: nil)
    @requests << {
      method: method,
      path: path,
      query: query,
      body: body,
      headers: headers,
      timeout: timeout
    }
    @responses.shift || {}
  end

  def multipart(path, fields:, file:, query: nil, headers: nil, timeout: nil)
    @requests << {
      method: 'POST',
      path: path,
      query: query,
      fields: fields,
      file: file,
      headers: headers,
      timeout: timeout
    }
    @responses.shift || {}
  end

  def stream_lines(method, path, query: nil, body: nil, headers: nil, timeout: nil)
    @requests << {
      method: method,
      path: path,
      query: query,
      body: body,
      headers: headers,
      timeout: timeout
    }
    (@stream_lines.shift || []).each
  end
end
