# frozen_string_literal: true

require 'buble'

client = Buble::Client.new

task = client.apps.generations.create('video-background-remover', {
                                        'source_video' => ['https://example.com/source.mp4'],
                                        'refine_foreground_edges' => true,
                                        'subject_is_person' => true
                                      })

result = client.apps.generations.wait('video-background-remover', task.dig('data', 'id'))
puts result.dig('data', 'result', 'videos', 0, 'url')
