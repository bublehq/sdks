# frozen_string_literal: true

require_relative 'test_helper'

class MediaModelsTest < Minitest::Test
  def test_lists_media_models_with_media_type_filter
    transport = FakeTransport.new
    transport.enqueue_response('data' => [])
    resource = Buble::MediaModelsResource.new(transport)

    resource.list(media_type: 'video')

    assert_equal 'GET', transport.requests[0][:method]
    assert_equal '/api/v1/media_models', transport.requests[0][:path]
    assert_equal({ media_type: 'video' }, transport.requests[0][:query])
  end
end
