# frozen_string_literal: true

require 'buble'

client = Buble::Client.new

task = client.generations.create(
  model: 'gork/grok-imagine-video',
  mode: 'text_to_video',
  prompt: 'A slow cinematic shot of a futuristic train station at sunrise.',
  duration: '5s',
  resolution: '480p',
  aspect_ratio: '16:9'
)

result = client.generations.wait(task.dig('data', 'id'), interval: 2, timeout: 900)
puts result.dig('data', 'result', 'videos', 0, 'url')
