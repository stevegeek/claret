# frozen_string_literal: true

module Claret
  module Parsing
    PAREN_MAP = {
      "(" => ")",
      "{" => "}",
      "[" => "]"
    }.freeze

    ParenGroup = Data.define(:items, :paren_type, :start_pos, :end_pos) do
      include Enumerable

      def paren_group?
        true
      end

      def paren_literal?
        false
      end

      def paren_type_reverse
        return unless paren_type
        PAREN_MAP[paren_type].tap do |char|
          raise "Unknown paren type: #{paren_type}" unless char
        end
      end

      def size
        items.size
      end

      def last
        items.last
      end

      def first
        items.first
      end

      def each(&block)
        items.each(&block)
      end

      def append(item)
        items << item
      end
      alias_method :<<, :append

      def index(...)
        items.index(...)
      end

      def [](index)
        if index.is_a?(Range)
          ParenGroup.new(items[index], paren_type)
        else
          items[index]
        end
      end

      def to_code
        body = map { _1.to_code }
        "#{paren_type}#{body.join}#{paren_type_reverse}"
      end

      def to_s
        body = map { _1.to_s }
        "#{paren_type}#{body.join}#{paren_type_reverse}"
      end
    end
  end
end
