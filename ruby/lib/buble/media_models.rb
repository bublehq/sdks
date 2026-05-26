# frozen_string_literal: true

module Buble
  class MediaModelsResource
    def initialize(http)
      @http = http
    end

    def list(media_type: nil, **query)
      @http.request('GET', '/api/v1/media_models', query: { media_type: media_type }.merge(query))
    end
  end
end
