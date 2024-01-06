# frozen_string_literal: true

require "test_helper"
require "claret/parsing/parens_parser"

module Claret
  module Parsing
    class ParensParserTest < Minitest::Test
      def test_parse
        scanner = StringScanner.new("hello, (world) test,, with {nested (parens)}")
        parens = ParensParser.new(scanner, "(")
        parsed = parens.parse
        assert_instance_of ParenGroup, parsed
        assert_equal "(", parens.paren_type
        assert_equal "", scanner.rest
        assert_equal "(", parsed[1].paren_type
        assert_equal "{", parsed[3].paren_type
        assert_equal "(hello, (world) test,, with {nested (parens)})", parsed.to_code
      end

      def test_empty_parens_with_comments
        scanner = StringScanner.new("() # Comments")
        parens = ParensParser.new(scanner)
        parsed = parens.parse
        assert_equal "()", parsed.first.to_code
        assert_equal "# Comments", parsed.last.to_code
        assert_instance_of EndlessGreedyLiteral, parsed.last
      end

      def test_empty_parens
        scanner = StringScanner.new("()")
        parens = ParensParser.new(scanner)
        parsed = parens.parse
        assert_equal "()", parsed.to_code
      end

      def test_allow_open_paren_group
        scanner = StringScanner.new("(")
        parens = ParensParser.new(scanner)
        assert_equal "()", parens.parse.to_code
      end

      def test_allow_unbalanced_parens
        scanner = StringScanner.new("(}")
        parens = ParensParser.new(scanner)
        assert_equal "()", parens.parse.to_code
      end

      def test_unbalanced_paren_group
        scanner = StringScanner.new("(([])")
        parens = ParensParser.new(scanner)
        assert_equal "(([]))", parens.parse.to_code
      end

      def test_unbalanced_quote_group
        scanner = StringScanner.new("(\"hello)")
        parens = ParensParser.new(scanner)
        assert_raises(ParensParser::ParenBalanceError) { parens.parse }
      end

      def test_empty_curly_with_whitespace
        scanner = StringScanner.new("{ }")
        parens = ParensParser.new(scanner)
        parsed = parens.parse
        assert_equal "{ }", parsed.to_code
      end

      def test_one_nested_curly_with_given_start_pos
        source = "[{Type hello}]"
        scanner = StringScanner.new(source)
        scanner.pos = 1
        parens = ParensParser.new(scanner, "[", 8, 8)
        parsed = parens.parse
        expected = ParenGroup.new(
          [ParenGroup.new([Literal.new("Type hello", 10, 19)], "{", 9, 20)],
          "[", 8, 21
        )
        assert_equal expected, parsed
        assert_equal "[{Type hello}]", parsed.to_code
      end

      def test_one_arg
        scanner = StringScanner.new("(Type hello)")
        parens = ParensParser.new(scanner)
        expected = ParenGroup.new(
          [
            ParenGroup.new(
              [
                Literal.new("Type hello", 1, 10)
              ],
              "(", 0, 11
            )
          ],
          nil, 0, 11
        )
        assert_equal expected, parens.parse
      end

      def test_one_arg_with_inner_strings
        scanner = StringScanner.new("(hello \"wo(rld\" 'te\\'st')")
        parens = ParensParser.new(scanner)
        expected = ParenGroup.new(
          [
            ParenGroup.new(
              [
                GreedyLiteral.new("hello \"wo(rld\"", 1, 14),
                GreedyLiteral.new(" 'te\\'st'", 15, 23)
              ],
              "(", 0, 24
            )
          ],
          nil, 0, 24
        )
        assert_equal expected, parens.parse
      end

      def test_one_nilable_type
        scanner = StringScanner.new("(?Type hello)")
        parens = ParensParser.new(scanner)
        expected = ParenGroup.new(
          [
            ParenGroup.new(
              [
                Literal.new("?Type hello", 1, 11)
              ],
              "(", 0, 12
            )
          ],
          nil, 0, 12
        )
        assert_equal expected, parens.parse
      end

      def test_no_parens
        source = "def test, foo"
        scanner = StringScanner.new(source)
        parens = ParensParser.new(scanner)
        parsed = parens.parse
        assert_equal parsed, ParenGroup.new([Literal.new(source, 0, source.size - 1)], nil, 0, source.size - 1)
        assert_equal source, parsed.to_code
      end

      def test_no_parens_and_comment
        source = "def test, foo # comment, about this"
        scanner = StringScanner.new(source)
        parens = ParensParser.new(scanner)
        parsed = parens.parse
        assert_equal parsed, ParenGroup.new([Literal.new("def test, foo ", 0, 13), EndlessGreedyLiteral.new("# comment, about this", 14, 34)], nil, 0, source.size - 1)
        assert_equal source, parsed.to_code
      end

      def test_parse_args_no_types
        scanner = StringScanner.new("@hello, world = :foo, @test: (@var + 4)")
        parens = ParensParser.new(scanner)
        assert_equal ParenGroup.new(
          [
            Literal.new("@hello, world = :foo, @test: ", 0, 28),
            ParenGroup.new([Literal.new("@var + 4", 30, 37)], "(", 29, 38)
          ],
          nil, 0, 38
        ), parens.parse
      end

      def test_parse_multiple_groups
        scanner = StringScanner.new("(hello, (world) test), with (another group [here]), and trailing string")
        parens = ParensParser.new(scanner)
        expected = ParenGroup.new(
          [
            ParenGroup.new(
              [
                Literal.new("hello, ", 1, 7),
                ParenGroup.new(
                  [
                    Literal.new("world", 9, 13)
                  ],
                  "(", 8, 14
                ),
                Literal.new(" test", 15, 19)
              ],
              "(", 0, 20
            ),
            Literal.new(", with ", 21, 27),
            ParenGroup.new(
              [
                Literal.new("another group ", 29, 42),
                ParenGroup.new(
                  [
                    Literal.new("here", 44, 47)
                  ],
                  "[", 43, 48
                )
              ],
              "(", 28, 49
            ),
            Literal.new(", and trailing string", 50, 70)
          ],
          nil, 0, 70
        )
        assert_equal expected, parens.parse
      end

      def test_a_method_sig_with_return_type
        scanner = StringScanner.new("(Type a, Type b) -> String")
        parens = ParensParser.new(scanner)
        expected = ParenGroup.new(
          [
            ParenGroup.new(
              [
                Literal.new("Type a, Type b", 1, 14)
              ],
              "(", 0, 15
            ),
            Literal.new(" -> String", 16, 25)
          ],
          nil, 0, 25
        )
        assert_equal expected, parens.parse
      end
    end
  end
end
