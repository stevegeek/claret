# frozen_string_literal: true

module Claret
  module Parsing
    ParenGroupLiteral = Data.define(:literal, :start_pos, :end_pos) do
      def paren_group?
        false
      end

      def paren_literal?
        true
      end

      def include?(...)
        literal.include?(...)
      end

      def split(...)
        literal.split(...)
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
