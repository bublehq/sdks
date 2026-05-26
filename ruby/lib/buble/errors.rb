# frozen_string_literal: true

module Buble
  class Error < StandardError; end

  class APIError < Error
    attr_reader :status, :code, :details, :response_body

    def initialize(message, status:, code: nil, details: nil, response_body: nil)
      super(message)
      @status = status
      @code = code
      @details = details
      @response_body = response_body
    end
  end

  class TimeoutError < Error
    attr_reader :timeout

    def initialize(message, timeout:)
      super(message)
      @timeout = timeout
    end
  end

  class GenerationFailedError < Error
    attr_reader :task

    def initialize(message, task:)
      super(message)
      @task = task
    end
  end

  class GenerationCanceledError < Error
    attr_reader :task

    def initialize(message, task:)
      super(message)
      @task = task
    end
  end

  class UnsupportedGenerationFieldError < Error
    attr_reader :field

    def initialize(field)
      super(%("#{field}" is an internal Buble field and is not supported by the public API.))
      @field = field
    end
  end
end
