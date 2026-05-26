# frozen_string_literal: true

require_relative 'test_helper'

class ChatTest < Minitest::Test
  def test_creates_openai_compatible_chat_without_wrapping_response
    transport = FakeTransport.new
    transport.enqueue_response('choices' => [{ 'message' => { 'content' => 'hello' } }])
    resource = Buble::ChatCompletionsResource.new(transport)

    response = resource.create(model: 'openai/gpt-5.4', messages: [{ role: 'user', content: 'hi' }])

    assert_equal 'hello', response.dig('choices', 0, 'message', 'content')
    assert_equal '/api/v1/chat/completions', transport.requests[0][:path]
    assert_equal false, transport.requests[0][:body]['stream']
  end

  def test_streams_openai_text
    transport = FakeTransport.new
    transport.enqueue_stream_lines([
                                     'data: {"choices":[{"delta":{"content":"hel"}}]}',
                                     '',
                                     'data: {"choices":[{"delta":{"content":"lo"}}]}',
                                     '',
                                     'data: [DONE]',
                                     ''
                                   ])
    resource = Buble::ChatCompletionsResource.new(transport)

    parts = resource.stream_text(model: 'openai/gpt-5.4', messages: [{ role: 'user', content: 'hi' }]).to_a

    assert_equal %w[hel lo], parts
    assert_equal true, transport.requests[0][:body]['stream']
  end

  def test_uses_gemini_generate_content_path
    transport = FakeTransport.new
    transport.enqueue_response('candidates' => [])
    resource = Buble::GeminiResource.new(transport)

    resource.generate_content('openai/gpt-5.4', 'contents' => [])

    assert_equal '/api/v1beta/models/openai/gpt-5.4:generateContent', transport.requests[0][:path]
  end
end
