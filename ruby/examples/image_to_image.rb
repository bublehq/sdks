# frozen_string_literal: true

require 'buble'

client = Buble::Client.new

uploaded = client.files.upload(
  Buble::FileUpload.from_path('reference.png', content_type: 'image/png'),
  file_type: 'image',
  model: 'google/nano-banana',
  mode: 'image_to_image'
)

task = client.generations.create(
  model: 'google/nano-banana',
  mode: 'image_to_image',
  prompt: 'Turn this reference into a polished ecommerce hero image.',
  image_urls: [uploaded.dig('data', 'url')]
)

result = client.generations.wait(task.dig('data', 'id'))
puts result.dig('data', 'result', 'images', 0, 'url')
