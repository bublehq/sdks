# frozen_string_literal: true

require 'json'
require 'buble'

client = Buble::Client.new

models = client.media_models.list(media_type: 'image')
puts JSON.generate(step: 'media_models', count: models.fetch('data', []).length)

chat = client.chat.completions.create(
  model: 'openai/gpt-5.4',
  messages: [
    { role: 'user', content: 'Reply with exactly: Buble Ruby SDK live smoke OK' }
  ],
  max_completion_tokens: 32
)
puts JSON.generate(step: 'chat', message: chat.dig('choices', 0, 'message', 'content'))
