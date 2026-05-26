# frozen_string_literal: true

require_relative 'streaming'

module Buble
  class ChatModelsResource
    def initialize(http)
      @http = http
    end

    def list
      @http.request('GET', '/api/v1/models')
    end
  end

  class ChatCompletionsResource
    def initialize(http)
      @http = http
    end

    def create(body = nil, **params)
      payload = normalize_body(body, params).merge('stream' => false)
      @http.request('POST', '/api/v1/chat/completions', body: payload)
    end

    def stream(body = nil, **params)
      payload = normalize_body(body, params).merge('stream' => true)
      Streaming.events_from_lines(@http.stream_lines('POST', '/api/v1/chat/completions', body: payload))
    end

    def stream_text(body = nil, **params)
      Streaming.text_stream(stream(body, **params), :openai)
    end

    private

    def normalize_body(body, params)
      source = body || params
      source.each_with_object({}) { |(key, value), out| out[key.to_s] = value }
    end
  end

  class MessagesResource
    def initialize(http)
      @http = http
    end

    def create(body = nil, **params)
      payload = normalize_body(body, params).merge('stream' => false)
      @http.request('POST', '/api/v1/messages', body: payload)
    end

    def stream(body = nil, **params)
      payload = normalize_body(body, params).merge('stream' => true)
      Streaming.events_from_lines(@http.stream_lines('POST', '/api/v1/messages', body: payload))
    end

    def stream_text(body = nil, **params)
      Streaming.text_stream(stream(body, **params), :anthropic)
    end

    private

    def normalize_body(body, params)
      source = body || params
      source.each_with_object({}) { |(key, value), out| out[key.to_s] = value }
    end
  end

  class GeminiResource
    def initialize(http)
      @http = http
    end

    def generate_content(model, body)
      @http.request('POST', "/api/v1beta/models/#{HTTP.encode_model_path(model)}:generateContent", body: body)
    end

    def stream_generate_content(model, body)
      path = "/api/v1beta/models/#{HTTP.encode_model_path(model)}:streamGenerateContent"
      Streaming.events_from_lines(
        @http.stream_lines('POST', path, body: body)
      )
    end

    def stream_text(model, body)
      Streaming.text_stream(stream_generate_content(model, body), :gemini)
    end
  end

  class ChatResource
    attr_reader :models, :completions, :messages, :gemini

    def initialize(http)
      @models = ChatModelsResource.new(http)
      @completions = ChatCompletionsResource.new(http)
      @messages = MessagesResource.new(http)
      @gemini = GeminiResource.new(http)
    end
  end
end
