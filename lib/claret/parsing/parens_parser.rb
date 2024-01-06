# frozen_string_literal: true

module Claret
  module Parsing
    class ParensParser
      include ::Claret::Utils::Logging

      class ParenBalanceError < StandardError; end

      def initialize(inner_text_scanner, paren_type = nil, start_pos = 0, start_offset = 0)
        @scanner = inner_text_scanner
        @paren_type = paren_type
        @start_pos = start_pos
        @start_offset = start_offset
      end

      attr_reader :scanner, :paren_type, :start_pos, :start_offset

      def parse
        debug "ParenGroup '#{paren_type || "n/a"}' with start at #{start_pos} - offset #{start_offset}"
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
        when *GREEDY_CHARS
          consume_until_same_paren_type
          reset_buffer
        when *OPENING_CHARS
          type = append_buffer_and_consume_character
          debug "Opening '#{type}' at #{current_scanner_index}"
          parse_next(type)
          reset_buffer
        when *CLOSING_CHARS
          debug "Closing '#{scanner.peek(1)}' at #{current_scanner_index}"
          append_buffer_and_consume_character
          :stop
        when *ENDLESS_GREEDY_CHARS
          consume_until_end
          :stop
        else
          # append any other characters to current buffer
          @current_buffer << scanner.getch
        end
      end

      def consume_until_same_paren_type
        # Consume characters until the same paren type is encountered. The paren character is included in the result
        paren_type_reverse = PAREN_MAP[scanner.peek(1)]
        consume_characters_until do |prev_char, next_char|
          raise ParenBalanceError, "Unexpected end of input when looking for closing '#{paren_type_reverse}' character" if scanner.eos?
          next_char == paren_type_reverse && prev_char != "\\"
        end
        append_buffer_to_result_if_not_empty(GreedyLiteral)
      end

      def consume_until_end
        # These will create a new literal, so first append any current buffer to result
        append_buffer_to_result_if_not_empty
        reset_buffer
        # Consume characters until the end of the input is encountered. The paren character is included in the result
        consume_characters_until do |_prev_char, next_char|
          next_char == "\n" || scanner.eos?
        end
        append_buffer_to_result_if_not_empty(EndlessGreedyLiteral)
      end

      def consume_characters_until
        prev_char = scanner.getch
        @current_buffer << prev_char
        loop do
          next_char = scanner.getch
          @current_buffer << next_char
          break if yield(prev_char, next_char)
          prev_char = next_char
        end
      end

      def append_buffer_and_consume_character
        append_buffer_to_result_if_not_empty
        scanner.getch
      end

      def parse_next(paren_type)
        # recursive call for next argument when opening parens encountered. Start position
        # is one character back from current scanner position (ie the opening paren which has
        # already been consumed)
        @result << ParensParser.new(scanner, paren_type, with_offset(current_scanner_index - 1), start_offset).parse
      end

      def append_buffer_to_result_if_not_empty(literal_class = Literal)
        @result << create_paren_group_literal_from_buffer(literal_class) unless @current_buffer.empty?
      end

      def create_paren_group_literal_from_buffer(literal_class)
        debug "#{literal_class.name} -- #{@current_buffer} -- at (#{current_buffer_start_pos}:#{current_buffer_end_pos})"
        literal_class.new(@current_buffer, current_buffer_start_pos, current_buffer_end_pos)
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
