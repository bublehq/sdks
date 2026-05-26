# frozen_string_literal: true

require 'buble'

client = Buble::Client.new

message = client.chat.messages.create(
  model: 'openai/gpt-5.4',
  system: 'You are concise.',
  messages: [
    { role: 'user', content: 'Summarize this release.' }
  ],
  max_tokens: 800
)

puts message
