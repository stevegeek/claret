# frozen_string_literal: true

require "forwardable"

module Claret
  module Parsing
    Literal = Data.define(:literal, :start_pos, :end_pos) do
      extend Forwardable

      def paren_group?
        false
      end

      def paren_literal?
        true
      end

      def_delegators :literal, :size, :empty?, :include?, :index, :match, :match?

      def split(delimiter = " ", limit = -1)
        delimiter_positions = literal.enum_for(:scan, delimiter).map { Regexp.last_match.begin(0) }

        results, last_index = handle_starting_delimiter(delimiter_positions, delimiter)
        results, last_index = create_substrings(results, delimiter_positions, delimiter, last_index, limit)
        handle_last_substring(results, last_index).map do |result|
          Literal.new(result[:substring], start_pos + result[:start_index], start_pos + result[:end_index])
        end
      end

      def merge(other_literal)
        with(literal: literal + other_literal.to_code, end_pos: end_pos + other_literal.size)
      end

      def prepend(str)
        new_literal = str + literal
        with(literal: new_literal, end_pos: start_pos + new_literal.size - 1)
      end

      def append(other)
        str = other.is_a?(String) ? other : other.to_code
        new_literal = literal + str
        with(literal: new_literal, end_pos: end_pos + str.size)
      end

      def blank?
        literal.strip.empty?
      end

      def to_literal
        self
      end

      def to_code
        literal
      end

      def to_s
        literal
      end

      private

      def handle_starting_delimiter(delimiter_positions, delimiter)
        last_index = 0
        results = []
        if delimiter_positions[0] == 0 && delimiter != " "
          results << {substring: "", start_index: 0, end_index: 0}
          last_index = delimiter.length
          delimiter_positions.shift
        end
        [results, last_index]
      end

      def create_substrings(results, delimiter_positions, delimiter, last_index, limit)
        delimiter_positions.each do |position|
          substring = literal[last_index...position]
          current_last_index = last_index
          last_index = position + delimiter.length
          next if substring.empty?
          results << {substring: substring, start_index: current_last_index, end_index: position - 1}
          break if results.size == limit
        end
        [results, last_index]
      end

      def handle_last_substring(results, last_index)
        literal_len = literal.length
        if last_index < literal_len
          results << {substring: literal[last_index..-1], start_index: last_index, end_index: literal_len - 1}
        elsif last_index == literal_len && delimiter_positions.last == literal_len - delimiter.length
          # Handle the case where the string ends with the delimiter?
        end
        results
      end
    end
  end
end
