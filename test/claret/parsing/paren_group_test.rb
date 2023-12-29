# frozen_string_literal: true

require "test_helper"
require "claret/parsing/paren_group"

module Claret
  module Parsing
    class ParenGroupTest < Minitest::Test
      def setup
        @paren_group = ParenGroup.new([], "(", 0, 3)
      end

      def test_paren_group?
        assert @paren_group.paren_group?
      end

      def test_paren_literal?
        refute @paren_group.paren_literal?
      end

      def test_blank?
        assert @paren_group.blank?
        @paren_group << ParenGroupLiteral.new("test", 0, 3)
        refute @paren_group.blank?
      end

      def test_paren_type_reverse
        assert_equal ")", @paren_group.paren_type_reverse
      end

      def test_append
        @paren_group.append(ParenGroupLiteral.new("test", 0, 3))
        assert_equal 1, @paren_group.size
      end

      def test_each
        @paren_group << ParenGroupLiteral.new("test", 0, 3)
        @paren_group.each do |item|
          assert item.paren_literal?
        end
      end

      def test_index
        literal = ParenGroupLiteral.new("test", 0, 3)
        @paren_group << literal
        assert_equal 0, @paren_group.index(literal)
      end

      def test_size
        @paren_group << ParenGroupLiteral.new("test", 0, 3)
        assert_equal 1, @paren_group.size
      end

      def test_first
        literal = ParenGroupLiteral.new("test", 0, 3)
        @paren_group << literal
        assert_equal literal, @paren_group.first
      end

      def test_last
        literal = ParenGroupLiteral.new("test", 0, 3)
        @paren_group << literal
        assert_equal literal, @paren_group.last
      end

      def test_brackets
        literal = ParenGroupLiteral.new("test", 0, 3)
        @paren_group << literal
        assert_equal literal, @paren_group[0]
      end

      def test_to_code
        @paren_group << ParenGroupLiteral.new("test", 0, 3)
        assert_equal "(test)", @paren_group.to_code
      end

      def test_to_s
        @paren_group << ParenGroupLiteral.new("test", 0, 3)
        assert_equal "(test)", @paren_group.to_s
      end
    end
  end
end
