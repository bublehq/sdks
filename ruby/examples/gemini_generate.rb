# frozen_string_literal: true

require 'buble'

client = Buble::Client.new

response = client.chat.gemini.generate_content('openai/gpt-5.4', {
                                                 contents: [
                                                   {
                                                     role: 'user',
                                                     parts: [
                                                       { text: 'Write a short launch summary.' }
                                                     ]
                                                   }
                                                 ]
                                               })

puts response
