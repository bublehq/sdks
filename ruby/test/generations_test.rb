# frozen_string_literal: true

require_relative 'test_helper'

class GenerationsTest < Minitest::Test
  def test_creates_flat_generation_body
    transport = FakeTransport.new
    transport.enqueue_response('data' => { 'id' => 'task_1' })
    resource = Buble::GenerationsResource.new(transport)

    resource.create(
      model: 'google/nano-banana',
      mode: 'text_to_image',
      prompt: 'hello',
      aspect_ratio: '1:1',
      output_format: 'png'
    )

    assert_equal '/api/v1/generations', transport.requests[0][:path]
    assert_equal(
      {
        'model' => 'google/nano-banana',
        'mode' => 'text_to_image',
        'prompt' => 'hello',
        'aspect_ratio' => '1:1',
        'output_format' => 'png'
      },
      transport.requests[0][:body]
    )
  end

  def test_rejects_internal_generation_fields
    resource = Buble::GenerationsResource.new(FakeTransport.new)

    error = assert_raises(Buble::UnsupportedGenerationFieldError) do
      resource.create(model: 'model', media_type: 'image')
    end

    assert_equal 'media_type', error.field
  end

  def test_waits_until_success
    transport = FakeTransport.new
    transport.enqueue_response('data' => { 'id' => 'task_1', 'status' => 'processing' })
    transport.enqueue_response('data' => { 'id' => 'task_1', 'status' => 'success' })
    resource = Buble::GenerationsResource.new(transport)

    result = resource.wait('task_1', interval: 0, timeout: 1)

    assert_equal 'success', result.dig('data', 'status')
    assert_equal '/api/v1/generations/task_1', transport.requests[0][:path]
  end

  def test_raises_on_failed_generation
    transport = FakeTransport.new
    transport.enqueue_response('data' => {
                                 'id' => 'task_1',
                                 'status' => 'failed',
                                 'error' => { 'message' => 'provider failed' }
                               })
    resource = Buble::GenerationsResource.new(transport)

    error = assert_raises(Buble::GenerationFailedError) do
      resource.wait('task_1', interval: 0, timeout: 1)
    end

    assert_equal 'provider failed', error.message
  end
end
