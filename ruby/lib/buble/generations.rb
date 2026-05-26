# frozen_string_literal: true

require 'time'

module Buble
  class GenerationsResource
    FORBIDDEN_FIELDS = %w[
      input
      options
      scene
      sub_mode_id
      subModeId
      provider
      mediaType
      media_type
      images
      image_input
      video_input
      audio_input
    ].freeze

    TERMINAL_STATUSES = %w[success failed canceled].freeze

    def initialize(http)
      @http = http
    end

    def create(model:, mode: nil, prompt: nil, image_urls: nil, start_frame: nil, end_frame: nil,
               video_urls: nil, audio_urls: nil, is_public: nil, copy_protected: nil, **params)
      body = compact_body({
        model: model,
        mode: mode,
        prompt: prompt,
        image_urls: image_urls,
        start_frame: start_frame,
        end_frame: end_frame,
        video_urls: video_urls,
        audio_urls: audio_urls,
        is_public: is_public,
        copy_protected: copy_protected
      }.merge(params))
      assert_public_body!(body)
      @http.request('POST', '/api/v1/generations', body: body)
    end

    def retrieve(id)
      @http.request('GET', "/api/v1/generations/#{HTTP.encode_segment(id)}")
    end

    def wait(id, interval: 2, timeout: 600, throw_on_failed: true, throw_on_canceled: true)
      deadline = Time.now + timeout

      loop do
        envelope = retrieve(id)
        task = envelope['data'] || {}
        status = task['status']
        if TERMINAL_STATUSES.include?(status)
          raise_if_terminal_error!(id, task, status, throw_on_failed, throw_on_canceled)
          return envelope
        end

        if Time.now >= deadline
          raise TimeoutError.new(
            "Generation #{id} did not finish within #{timeout} seconds.",
            timeout: timeout
          )
        end

        sleep interval
      end
    end

    private

    def raise_if_terminal_error!(id, task, status, throw_on_failed, throw_on_canceled)
      if status == 'failed' && throw_on_failed
        error = task['error'] || {}
        raise GenerationFailedError.new(error['message'] || 'Generation failed.', task: task)
      end

      return unless status == 'canceled' && throw_on_canceled

      raise GenerationCanceledError.new("Generation #{id} was canceled.", task: task)
    end

    def compact_body(body)
      body.each_with_object({}) do |(key, value), out|
        next if value.nil?
        next if value.respond_to?(:empty?) && value.empty?

        out[key.to_s] = value
      end
    end

    def assert_public_body!(body)
      body.each_key do |key|
        raise UnsupportedGenerationFieldError, key if FORBIDDEN_FIELDS.include?(key.to_s)
      end
    end
  end
end
