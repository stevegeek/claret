# frozen_string_literal: true

require "test_helper"
require "claret/parsing/args_parser"

module Claret
  module Parsing
    class ArgsParserTest < Minitest::Test
      def test_parse
        scanner = StringScanner.new("(hello , (world)  test , with {nested (parens)}, and, more args, type here: (cool))")
        parens = ParensParser.new(scanner).parse
        args = ArgsParser.new(parens.first)
        expected = [
          Arg.new(name: "hello", type: nil, name_raw_str: "hello ", start_pos: 1, end_pos: 5),
          Arg.new(name: "test", type: "(world)", name_raw_str: "  test ", start_pos: 9, end_pos: 21),
          nil,
          Arg.new(name: "and", type: nil, name_raw_str: " and", start_pos: 49, end_pos: 51),
          Arg.new(name: "args", type: "more", name_raw_str: "args", start_pos: 54, end_pos: 62),
          Arg.new(name: "here", type: "type", name_raw_str: "here: ", start_pos: 65, end_pos: 73)
        ]
        assert_equal expected, args.parse
      end

      def test_parse_with_no_args
        scanner = StringScanner.new("()")
        parens = ParensParser.new(scanner).parse
        args = ArgsParser.new(parens.first)
        assert_equal [], args.parse
      end

      def test_parse_with_single_arg
        scanner = StringScanner.new("(single_arg)")
        parens = ParensParser.new(scanner).parse
        args = ArgsParser.new(parens.first)
        expected = [
          Arg.new(name: "single_arg", type: nil, name_raw_str: "single_arg", start_pos: 1, end_pos: 10)
        ]
        assert_equal expected, args.parse
      end

      def test_parse_with_arg_and_type
        scanner = StringScanner.new("(type single_arg)")
        parens = ParensParser.new(scanner).parse
        args = ArgsParser.new(parens.first)
        expected = [
          Arg.new(name: "single_arg", type: "type", name_raw_str: "single_arg", start_pos: 1, end_pos: 15)
        ]
        assert_equal expected, args.parse
      end

      def test_parse_with_arg_and_nilable_type
        scanner = StringScanner.new("(?type single_arg)")
        parens = ParensParser.new(scanner).parse
        args = ArgsParser.new(parens.first)
        expected = [
          Arg.new(name: "single_arg", type: "?type", name_raw_str: "single_arg", start_pos: 1, end_pos: 16)
        ]
        assert_equal expected, args.parse
      end

      def test_parse_with_optional_arg_and_no_type
        scanner = StringScanner.new("(single_arg = 1)")
        parens = ParensParser.new(scanner).parse
        args = ArgsParser.new(parens.first)
        expected = [
          Arg.new(name: "single_arg", type: "?untyped", name_raw_str: "single_arg = 1", start_pos: 1, end_pos: 10)
        ]
        assert_equal expected, args.parse
      end

      def test_parse_with_optional_kwarg_and_no_type
        scanner = StringScanner.new("(single_arg: 1)")
        parens = ParensParser.new(scanner).parse
        args = ArgsParser.new(parens.first)
        expected = [
          Arg.new(name: "single_arg", type: "?untyped", name_raw_str: "single_arg: 1", start_pos: 1, end_pos: 10)
        ]
        assert_equal expected, args.parse
      end

      def test_parse_with_optional_arg_and_type
        scanner = StringScanner.new("(Integer single_arg = 1)")
        parens = ParensParser.new(scanner).parse
        args = ArgsParser.new(parens.first)
        expected = [
          Arg.new(name: "single_arg", type: "?Integer", name_raw_str: "single_arg = 1", start_pos: 1, end_pos: 18)
        ]
        assert_equal expected, args.parse
      end

      def test_parse_with_optional_kwarg_and_type
        scanner = StringScanner.new("(Integer single_arg: 1)")
        parens = ParensParser.new(scanner).parse
        args = ArgsParser.new(parens.first)
        expected = [
          Arg.new(name: "single_arg", type: "?Integer", name_raw_str: "single_arg: 1", start_pos: 1, end_pos: 18)
        ]
        assert_equal expected, args.parse
      end

      def test_parse_with_arg_and_type_in_parens
        scanner = StringScanner.new("((type | complex[generic ]  )  single_arg)")
        parens = ParensParser.new(scanner).parse
        args = ArgsParser.new(parens.first)
        expected = [
          Arg.new(name: "single_arg", type: "(type | complex[generic ]  )", name_raw_str: "  single_arg", start_pos: 1, end_pos: 40)
        ]
        assert_equal expected, args.parse
      end

      def test_parse_with_multiple_args
        scanner = StringScanner.new("(arg1, arg2, arg3)")
        parens = ParensParser.new(scanner).parse
        args = ArgsParser.new(parens.first)
        expected = [
          Arg.new(name: "arg1", type: nil, name_raw_str: "arg1", start_pos: 1, end_pos: 4),
          Arg.new(name: "arg2", type: nil, name_raw_str: " arg2", start_pos: 7, end_pos: 10),
          Arg.new(name: "arg3", type: nil, name_raw_str: " arg3", start_pos: 13, end_pos: 16)
        ]
        assert_equal expected, args.parse
      end

      def test_parse_with_multiple_args_and_types
        scanner = StringScanner.new("(type1 arg1, type2 arg2, type3 arg3)")
        parens = ParensParser.new(scanner).parse
        args = ArgsParser.new(parens.first)
        expected = [
          Arg.new(name: "arg1", type: "type1", name_raw_str: "arg1", start_pos: 1, end_pos: 10),
          Arg.new(name: "arg2", type: "type2", name_raw_str: "arg2", start_pos: 13, end_pos: 22),
          Arg.new(name: "arg3", type: "type3", name_raw_str: "arg3", start_pos: 25, end_pos: 34)
        ]
        assert_equal expected, args.parse
      end
    end
  end
end
