# frozen_string_literal: true

require_relative 'generations'
require_relative 'apps'
require_relative 'chat'
require_relative 'files'
require_relative 'http'
require_relative 'media_models'

module Buble
  class Client
    attr_reader :media_models, :files, :generations, :apps, :chat

    def initialize(api_key: nil, base_url: nil, timeout: HTTP::DEFAULT_TIMEOUT, headers: {}, transport: nil)
      resolved_api_key = first_present(api_key, ENV.fetch('BUBLE_API_KEY', nil))
      resolved_base_url = first_present(base_url, ENV.fetch('BUBLE_BASE_URL', nil), HTTP::DEFAULT_BASE_URL)
      @transport = transport || HTTP.new(
        api_key: resolved_api_key,
        base_url: resolved_base_url,
        timeout: timeout,
        headers: headers
      )
      @media_models = MediaModelsResource.new(@transport)
      @files = FilesResource.new(@transport)
      @generations = GenerationsResource.new(@transport)
      @apps = AppsResource.new(@transport)
      @chat = ChatResource.new(@transport)
    end

    private

    def first_present(*values)
      values.find { |value| value && !value.to_s.strip.empty? }
    end
  end
end
