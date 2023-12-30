# frozen_string_literal: true

require "forwardable"

module Claret
  module Parsing
    ParenGroupLiteral = Data.define(:literal, :start_pos, :end_pos) do
      extend Forwardable

      def paren_group?
        false
      end

      def paren_literal?
        true
      end

      def_delegators :literal, :size, :empty?, :include?, :index, :match, :match?

      def split(...)
        literal.split(...).map do
          start_offset = start_pos + literal.index(_1)
          ParenGroupLiteral.new(_1, start_offset, start_offset + _1.size - 1)
        end
      end

      def merge(other_literal)
        with(literal: literal + other_literal.literal, end_pos: end_pos + other_literal.size)
      end

      def prepend(str)
        new_literal = str + literal
        with(literal: new_literal, end_pos: start_pos + new_literal.size - 1)
      end

      def append(str)
        new_literal = literal + str
        with(literal: new_literal, end_pos: end_pos + str.size)
      end

      def blank?
        literal.strip.empty?
      end

      def to_code
        literal
      end

      def to_s
        literal
      end
    end
  end
end
