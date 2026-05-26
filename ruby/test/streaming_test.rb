# frozen_string_literal: true

require_relative 'test_helper'

class StreamingTest < Minitest::Test
  def test_parses_multiline_data_event
    parser = Buble::Streaming::SSEParser.new

    assert_nil parser.push_line('event: message')
    assert_nil parser.push_line('data: first')
    assert_nil parser.push_line('data: second')
    event = parser.push_line('')

    assert_equal 'message', event.event
    assert_equal "first\nsecond", event.data
  end

  def test_extracts_anthropic_text
    event = Buble::Streaming::Event.new(
      data: '{"delta":{"text":"hello"}}',
      json: { 'delta' => { 'text' => 'hello' } }
    )

    assert_equal 'hello', Buble::Streaming.text_from_event(event, :anthropic)
  end
end
