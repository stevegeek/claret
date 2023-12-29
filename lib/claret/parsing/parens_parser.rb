# frozen_string_literal: true

module Claret
  module Parsing
    class ParensParser
      include ::Claret::Utils::Logging

      def initialize(inner_text_scanner, paren_type = nil, start_pos = 0, start_offset = 0)
        @scanner = inner_text_scanner
        @paren_type = paren_type
        @start_pos = start_pos
        @start_offset = start_offset
      end

      attr_reader :scanner, :paren_type, :start_pos, :start_offset

      def parse
        debug "Paren group '#{paren_type || "n/a"}' with start at #{start_pos} - offset #{start_offset}"
        @result = ParenGroup.new([], paren_type, start_pos, nil)
        reset_buffer

        continue_parsing = parse_until_stop

        # Add anything remaining in current to result (ie after last closing parens)
        append_buffer_to_result_if_not_empty unless continue_parsing == :stop

        # Set end position of result
        end_pos = with_offset(current_scanner_index - 1)
        @result.with(end_pos: end_pos)
      end

      private

      def parse_until_stop
        continue_parsing = true
        until scanner.eos? || continue_parsing == :stop
          continue_parsing = handle_next_character
        end
        continue_parsing
      end

      def handle_next_character
        case scanner.peek(1)
        when "(", "{", "["
          type = consume_character_and_append_buffer
          parse_next(type)
          reset_buffer
        when ")", "}", "]"
          consume_character_and_append_buffer
          reset_buffer
          :stop
        else
          # append any other characters to current buffer
          @current_buffer << scanner.getch
        end
      end

      def consume_character_and_append_buffer
        append_buffer_to_result_if_not_empty
        scanner.getch
      end

      def parse_next(paren_type)
        # recursive call for next argument when opening parens encountered. Start position
        # is one character back from current scanner position (ie the opening paren which has
        # already been consumed)
        @result << ParensParser.new(scanner, paren_type, with_offset(current_scanner_index - 1), start_offset).parse
      end

      def append_buffer_to_result_if_not_empty
        @result << create_paren_group_literal_from_buffer unless @current_buffer.empty?
      end

      def create_paren_group_literal_from_buffer
        debug "Paren group literal at (#{current_buffer_start_pos}:#{current_buffer_end_pos})"
        ParenGroupLiteral.new(@current_buffer, current_buffer_start_pos, current_buffer_end_pos)
      end

      def current_buffer_start_pos
        @current_buffer_start
      end

      def current_buffer_end_pos
        @current_buffer_start + @current_buffer.size - 1
      end

      def reset_buffer
        @current_buffer_start = with_offset(current_scanner_index)
        @current_buffer = +"" unless @current_buffer == ""
      end

      def current_scanner_index
        scanner.pos
      end

      def with_offset(index)
        start_offset + index
      end
    end
  end
end
