# frozen_string_literal: true

require_relative 'test_helper'

class AppsTest < Minitest::Test
  def test_retrieves_app_with_encoded_path
    transport = FakeTransport.new
    transport.enqueue_response('data' => {})
    resource = Buble::AppsResource.new(transport)

    resource.retrieve('video background')

    assert_equal '/api/v1/apps/video%20background', transport.requests[0][:path]
  end

  def test_creates_app_generation_with_flat_params
    transport = FakeTransport.new
    transport.enqueue_response('data' => { 'id' => 'task_1' })
    resource = Buble::AppsResource.new(transport)

    resource.generations.create('video-background-remover', {
                                  'source_video' => ['https://example.com/source.mp4'],
                                  'subject_is_person' => true
                                })

    assert_equal '/api/v1/apps/video-background-remover/generations', transport.requests[0][:path]
    assert_equal true, transport.requests[0][:body]['subject_is_person']
  end
end
