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
    end
  end
end
