# frozen_string_literal: true

require "forwardable"

module Claret
  module Parsing
    PAREN_MAP = {
      "\"" => "\"",
      "'" => "'",
      "(" => ")",
      "{" => "}",
      "[" => "]"
    }.freeze

    # These are the parens that can be nested inside of each other
    OPENING_CHARS = ["(", "{", "["].freeze
    CLOSING_CHARS = [")", "}", "]"].freeze

    # Greedy parens are ones that nothing can be nested inside of (the parser will consume characters until another
    # character is found (if escaped with a backslash they will be ignored)
    GREEDY_CHARS = ["\"", "'"].freeze

    ENDLESS_GREEDY_CHARS = ["#"].freeze

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

      def_delegators :to_literal, :match, :match?

      def paren_type_reverse
        return unless paren_type
        PAREN_MAP[paren_type].tap do |char|
          raise "Unknown paren type: #{paren_type}" unless char
        end
      end

      def append(item)
        item = Literal.new(item, end_pos + 1, end_pos + item.size) if item.is_a?(String)
        items << item
        self
      end
      alias_method :<<, :append

      def_delegators :items, :each, :index, :rindex, :size, :first, :last

      def [](index)
        if index.is_a?(Range)
          range = items[index]
          first = range.first
          last = range.last
          ParenGroup.new(range, paren_type, first&.start_pos, last&.end_pos)
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
        Literal.new(literal_str, start_pos, start_pos + literal_str.size - 1)
      end

      def to_s
        body = map { _1.to_s }
        "#{paren_type}#{body.join}#{paren_type_reverse}"
      end
    end
  end
end
