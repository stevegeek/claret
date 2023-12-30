# frozen_string_literal: true

require "forwardable"

module Claret
  module Parsing
    PAREN_MAP = {
      "(" => ")",
      "{" => "}",
      "[" => "]"
    }.freeze

    ParenGroup = Data.define(:items, :paren_type, :start_pos, :end_pos) do
      extend Forwardable
      include Enumerable

      def paren_group?
        true
      end

      def paren_literal?
        false
      end

      def blank?
        items.empty? || items.all?(&:blank?)
      end

      def paren_type_reverse
        return unless paren_type
        PAREN_MAP[paren_type].tap do |char|
          raise "Unknown paren type: #{paren_type}" unless char
        end
      end

      def append(item)
        items << item
      end
      alias_method :<<, :append

      def_delegators :items, :each, :index, :size, :first, :last

      def [](index)
        if index.is_a?(Range)
          range = items[index]
          ParenGroup.new(range, paren_type, range.first.start_pos, range.last.end_pos)
        else
          items[index]
        end
      end

      def to_code
        body = map { _1.to_code }
        "#{paren_type}#{body.join}#{paren_type_reverse}"
      end

      def to_literal
        literal_str = to_code
        ParenGroupLiteral.new(literal_str, start_pos, start_pos + literal_str.size - 1)
      end

      def to_s
        body = map { _1.to_s }
        "#{paren_type}#{body.join}#{paren_type_reverse}"
      end
    end
  end
end
