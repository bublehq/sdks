# frozen_string_literal: true

require 'buble'

client = Buble::Client.new

completion = client.chat.completions.create(
  model: 'openai/gpt-5.4',
  messages: [
    { role: 'user', content: 'Write a short launch summary.' }
  ],
  max_completion_tokens: 800
)

puts completion.dig('choices', 0, 'message', 'content')
