# frozen_string_literal: true

require 'buble'

client = Buble::Client.new

task = client.generations.create(
  model: 'google/nano-banana',
  mode: 'text_to_image',
  prompt: 'A cinematic product photo of a matte black espresso cup',
  aspect_ratio: '1:1',
  output_format: 'png'
)

result = client.generations.wait(task.dig('data', 'id'))
puts result.dig('data', 'result', 'images', 0, 'url')
