# frozen_string_literal: true

module Buble
  class AppGenerationsResource
    TERMINAL_STATUSES = GenerationsResource::TERMINAL_STATUSES

    def initialize(http)
      @http = http
    end

    def create(app_id, params = {})
      @http.request('POST', "/api/v1/apps/#{HTTP.encode_segment(app_id)}/generations", body: params)
    end

    def retrieve(app_id, id)
      @http.request('GET', "/api/v1/apps/#{HTTP.encode_segment(app_id)}/generations/#{HTTP.encode_segment(id)}")
    end

    def wait(app_id, id, interval: 2, timeout: 600, throw_on_failed: true, throw_on_canceled: true)
      deadline = Time.now + timeout

      loop do
        envelope = retrieve(app_id, id)
        task = envelope['data'] || {}
        status = task['status']
        if TERMINAL_STATUSES.include?(status)
          raise_if_terminal_error!(id, task, status, throw_on_failed, throw_on_canceled)
          return envelope
        end

        if Time.now >= deadline
          raise TimeoutError.new(
            "App generation #{id} did not finish within #{timeout} seconds.",
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

      raise GenerationCanceledError.new("App generation #{id} was canceled.", task: task)
    end
  end

  class AppsResource
    attr_reader :generations

    def initialize(http)
      @http = http
      @generations = AppGenerationsResource.new(http)
    end

    def list
      @http.request('GET', '/api/v1/apps')
    end

    def retrieve(app_id)
      @http.request('GET', "/api/v1/apps/#{HTTP.encode_segment(app_id)}")
    end
  end
end
