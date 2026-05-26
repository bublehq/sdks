# frozen_string_literal: true

require 'json'

module Buble
  module Streaming
    Event = Struct.new(:event, :data, :json, keyword_init: true)

    class SSEParser
      def initialize
        @event = nil
        @data = []
      end

      def push_line(line)
        line = line.to_s.sub(/\r\z/, '')
        return finish_event if line.empty?
        return nil if line.start_with?(':')

        field, value = line.split(':', 2)
        value = value ? value.sub(/\A /, '') : ''

        case field
        when 'event'
          @event = value
        when 'data'
          @data << value
        end
        nil
      end

      def finish
        finish_event
      end

      private

      def finish_event
        return nil if @event.nil? && @data.empty?

        data = @data.join("\n")
        json = parse_json(data)
        event = Event.new(event: @event, data: data, json: json)
        @event = nil
        @data = []
        event
      end

      def parse_json(data)
        return nil if data.empty? || data == '[DONE]'

        JSON.parse(data)
      rescue JSON::ParserError
        nil
      end
    end

    module_function

    def events_from_lines(lines)
      Enumerator.new do |yielder|
        parser = SSEParser.new
        lines.each do |line|
          event = parser.push_line(line)
          yielder << event if event
        end
        final = parser.finish
        yielder << final if final
      end
    end

    def text_from_event(event, protocol)
      return nil if event.data == '[DONE]'

      body = event.json
      return nil unless body.is_a?(Hash)

      case protocol
      when :openai
        body.dig('choices', 0, 'delta', 'content')
      when :anthropic
        body.dig('delta', 'text')
      when :gemini
        body.dig('candidates', 0, 'content', 'parts', 0, 'text')
      end
    end

    def text_stream(events, protocol)
      Enumerator.new do |yielder|
        events.each do |event|
          text = text_from_event(event, protocol)
          yielder << text if text && !text.empty?
        end
      end
    end
  end
end
