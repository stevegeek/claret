module Claret
  module Parsing
    class Parens
      def initialize(scanner)
        @scanner = scanner
      end

      attr_reader :scanner

      def parse
        reset_parse_result
        reset_buffer

        continue_parsing = true
        until scanner.eos? || continue_parsing == :stop
          continue_parsing = handle_next_character
        end

        # Add anything remaining in current to result (ie after last closing parens)
        append_buffer_to_result_if_not_empty unless continue_parsing == :stop
        @result
      end

      def reset
        reset_parse_result
        reset_buffer
        scanner.reset
      end

      private

      def handle_next_character
        case scanner.peek(1)
        when "("
          consume_and_append_buffer
          parse_next
        when ")"
          consume_and_append_buffer
          :stop
        when ","
          consume_and_append_buffer
          parse_next
        else
          # append any other characters to current buffer
          @current_buffer << scanner.getch
        end
      end

      def consume_and_append_buffer
        scanner.getch # consume the current character
        append_buffer_to_result_if_not_empty
      end

      def parse_next
        # recursive call for next argument when opening parens encountered. At every comma we also add to stack,
        # which lets us know when we're at the end of an arg.
        @result << Parens.new(scanner).parse
      end

      def append_buffer_to_result_if_not_empty
        stripped = @current_buffer.strip
        separator = stripped.empty?
        @result << stripped unless separator
        reset_buffer
      end

      def reset_parse_result
        @result = []
      end

      def reset_buffer
        @current_buffer = ""
      end
    end
  end
end
