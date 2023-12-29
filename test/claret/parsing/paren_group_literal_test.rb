# frozen_string_literal: true

require "test_helper"
require "claret/parsing/paren_group_literal"

module Claret
  module Parsing
    class ParenGroupLiteralTest < Minitest::Test
      def setup
        @paren_group_literal = ParenGroupLiteral.new("test", 0, 3)
      end

      def test_paren_group?
        refute @paren_group_literal.paren_group?
      end

      def test_paren_literal?
        assert @paren_group_literal.paren_literal?
      end

      def test_size
        assert_equal 4, @paren_group_literal.size
      end

      def test_empty?
        refute @paren_group_literal.empty?
      end

      def test_include?
        assert @paren_group_literal.include?("e")
        refute @paren_group_literal.include?("z")
      end

      def test_index
        assert_equal 1, @paren_group_literal.index("e")
      end

      def test_match
        assert @paren_group_literal.match(/es/)
        refute @paren_group_literal.match(/az/)
      end

      def test_match?
        assert @paren_group_literal.match?("es")
        refute @paren_group_literal.match?("az")
      end

      def test_split
        split_literals = @paren_group_literal.split("e")
        assert_equal 2, split_literals.size
        assert_equal "t", split_literals.first.literal
        assert_equal "st", split_literals.last.literal
      end

      def test_split_with_positions
        literal = ParenGroupLiteral.new("testing", 0, 6)
        split_literals = literal.split("t")

        assert_equal 3, split_literals.size

        assert_equal "", split_literals[0].literal
        assert_equal 0, split_literals[0].start_pos
        assert_equal(-1, split_literals[0].end_pos)

        assert_equal "es", split_literals[1].literal
        assert_equal 1, split_literals[1].start_pos
        assert_equal 2, split_literals[1].end_pos

        assert_equal "ing", split_literals[2].literal
        assert_equal 4, split_literals[2].start_pos
        assert_equal 6, split_literals[2].end_pos
      end

      def test_merge
        literal1 = ParenGroupLiteral.new("test", 0, 3)
        literal2 = ParenGroupLiteral.new("ing", 0, 2)
        merged_literal = literal1.merge(literal2)

        assert_equal "testing", merged_literal.literal
        assert_equal 6, merged_literal.end_pos
      end

      def test_blank?
        refute @paren_group_literal.blank?
        blank_literal = ParenGroupLiteral.new(" ", 0, 0)
        assert blank_literal.blank?
      end

      def test_to_code
        assert_equal "test", @paren_group_literal.to_code
      end

      def test_to_s
        assert_equal "test", @paren_group_literal.to_s
      end
    end
  end
end
