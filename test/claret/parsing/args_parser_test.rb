# frozen_string_literal: true

require "test_helper"

module Claret
  module Parsing
    class ArgsParserTest < Minitest::Test
      def test_parse
        scanner = StringScanner.new("(hello , (world)  test , with {nested (parens)}, and, more args, type here: (cool), (Integer | Float) @age = (1 + 2))")
        parens = ParensParser.new(scanner).parse
        args = ArgsParser.new(parens.first)
        expected = [
          Arg.create(name: "hello", type: nil, start_pos: 1, end_pos: 5, name_start_pos: 1, name_end_pos: 5, type_start_pos: nil, type_end_pos: nil),
          Arg.create(name: "test", type: "(world)", start_pos: 9, end_pos: 21, name_start_pos: 18, name_end_pos: 21, type_start_pos: 9, type_end_pos: 15),
          nil,
          Arg.create(name: "and", type: nil, start_pos: 49, end_pos: 51, name_start_pos: 49, name_end_pos: 51, type_start_pos: nil, type_end_pos: nil),
          Arg.create(name: "args", type: "more", start_pos: 54, end_pos: 62, name_start_pos: 59, name_end_pos: 62, type_start_pos: 54, type_end_pos: 57),
          Arg.create(name: "here", type: "type", start_pos: 65, end_pos: 73, name_start_pos: 70, name_end_pos: 73, type_start_pos: 65, type_end_pos: 68, method_arg_type: :keyword, optional: true),
          Arg.create(name: "@age", type: "(Integer | Float)", start_pos: 84, end_pos: 105, name_start_pos: 102, name_end_pos: 105, type_start_pos: 84, type_end_pos: 100, optional: true, ivar: true)
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
          Arg.create(name: "single_arg", type: nil, start_pos: 1, end_pos: 10, name_start_pos: 1, name_end_pos: 10, type_start_pos: nil, type_end_pos: nil)
        ]
        assert_equal expected, args.parse
      end

      def test_parse_with_arg_and_type
        scanner = StringScanner.new("(type single_arg)")
        parens = ParensParser.new(scanner).parse
        args = ArgsParser.new(parens.first)
        expected = [
          Arg.create(name: "single_arg", type: "type", start_pos: 1, end_pos: 15, name_start_pos: 6, name_end_pos: 15, type_start_pos: 1, type_end_pos: 4)
        ]
        assert_equal expected, args.parse
      end

      def test_parse_with_arg_and_type_and_ivar
        scanner = StringScanner.new("(type @single_arg)")
        parens = ParensParser.new(scanner).parse
        args = ArgsParser.new(parens.first)
        expected = [
          Arg.create(
            name: "@single_arg",
            type: "type",
            ivar: true,
            start_pos: 1, end_pos: 16, name_start_pos: 6, name_end_pos: 16, type_start_pos: 1, type_end_pos: 4
          )
        ]
        assert_equal expected, args.parse
      end

      def test_parse_with_arg_and_nilable_type
        scanner = StringScanner.new("(?type single_arg)")
        parens = ParensParser.new(scanner).parse
        args = ArgsParser.new(parens.first)
        expected = [
          Arg.create(
            name: "single_arg",
            type: "?type",
            optional: true,
            start_pos: 1, end_pos: 16, name_start_pos: 7, name_end_pos: 16, type_start_pos: 1, type_end_pos: 5
          )
        ]
        assert_equal expected, args.parse
      end

      def test_parse_with_optional_arg_and_no_type
        scanner = StringScanner.new("(single_arg = 1)")
        parens = ParensParser.new(scanner).parse
        args = ArgsParser.new(parens.first)
        expected = [
          Arg.create(name: "single_arg", type: nil, optional: true, start_pos: 1, end_pos: 10, name_start_pos: 1, name_end_pos: 10)
        ]
        assert_equal expected, args.parse
      end

      def test_parse_with_optional_kwarg_and_no_type
        scanner = StringScanner.new("(single_arg: 1)")
        parens = ParensParser.new(scanner).parse
        args = ArgsParser.new(parens.first)
        expected = [
          Arg.create(name: "single_arg", type: nil, optional: true, method_arg_type: :keyword, start_pos: 1, end_pos: 10, name_start_pos: 1, name_end_pos: 10)
        ]
        assert_equal expected, args.parse
      end

      def test_parse_with_optional_kwarg_and_no_type_and_group
        scanner = StringScanner.new("(single_arg: (123 + 123).foo)")
        parens = ParensParser.new(scanner).parse
        args = ArgsParser.new(parens.first)
        expected = [
          Arg.create(name: "single_arg", type: nil, optional: true, method_arg_type: :keyword, start_pos: 1, end_pos: 10, name_start_pos: 1, name_end_pos: 10)
        ]
        assert_equal expected, args.parse
      end

      def test_parse_with_optional_arg_and_type
        scanner = StringScanner.new("(Integer single_arg = 1)")
        parens = ParensParser.new(scanner).parse
        args = ArgsParser.new(parens.first)
        expected = [
          Arg.create(name: "single_arg", type: "Integer", optional: true, start_pos: 1, end_pos: 18, name_start_pos: 9, name_end_pos: 18, type_start_pos: 1, type_end_pos: 7)
        ]
        assert_equal expected, args.parse
      end

      def test_parse_with_optional_kwarg_and_type
        scanner = StringScanner.new("(Integer single_arg: 1)")
        parens = ParensParser.new(scanner).parse
        args = ArgsParser.new(parens.first)
        expected = [
          Arg.create(name: "single_arg", type: "Integer", optional: true, method_arg_type: :keyword, start_pos: 1, end_pos: 18, name_start_pos: 9, name_end_pos: 18, type_start_pos: 1, type_end_pos: 7)
        ]
        assert_equal expected, args.parse
      end

      def test_parse_with_explicit_optional_type
        scanner = StringScanner.new("(?Integer single_arg)")
        parens = ParensParser.new(scanner).parse
        args = ArgsParser.new(parens.first)
        expected = [
          Arg.create(name: "single_arg", type: "?Integer", optional: true, start_pos: 1, end_pos: 19, name_start_pos: 10, name_end_pos: 19, type_start_pos: 1, type_end_pos: 8)
        ]
        assert_equal expected, args.parse
      end

      def test_parse_with_explicit_optional_type_and_ivar
        scanner = StringScanner.new("(?Integer @single_arg)")
        parens = ParensParser.new(scanner).parse
        args = ArgsParser.new(parens.first)
        expected = [
          Arg.create(name: "@single_arg", type: "?Integer", optional: true, ivar: true, start_pos: 1, end_pos: 20, name_start_pos: 10, name_end_pos: 20, type_start_pos: 1, type_end_pos: 8)
        ]
        assert_equal expected, args.parse
      end

      def test_parse_with_arg_and_type_in_parens
        scanner = StringScanner.new("((type | complex[generic ]  )  single_arg)")
        parens = ParensParser.new(scanner).parse
        args = ArgsParser.new(parens.first)
        expected = [
          Arg.create(name: "single_arg", type: "(type | complex[generic ]  )", start_pos: 1, end_pos: 40, name_start_pos: 31, name_end_pos: 40, type_start_pos: 1, type_end_pos: 28)
        ]
        assert_equal expected, args.parse
      end

      def test_parse_with_multiple_args
        scanner = StringScanner.new("(arg1, arg2, arg3)")
        parens = ParensParser.new(scanner).parse
        args = ArgsParser.new(parens.first)
        expected = [
          Arg.create(name: "arg1", type: nil, start_pos: 1, end_pos: 4, name_start_pos: 1, name_end_pos: 4),
          Arg.create(name: "arg2", type: nil, start_pos: 7, end_pos: 10, name_start_pos: 7, name_end_pos: 10),
          Arg.create(name: "arg3", type: nil, start_pos: 13, end_pos: 16, name_start_pos: 13, name_end_pos: 16)
        ]
        assert_equal expected, args.parse
      end

      def test_parse_with_multiple_args_and_types
        scanner = StringScanner.new("(type1 arg1, type2 arg2, type3 arg3)")
        parens = ParensParser.new(scanner).parse
        args = ArgsParser.new(parens.first)
        expected = [
          Arg.create(name: "arg1", type: "type1", start_pos: 1, end_pos: 10, name_start_pos: 7, name_end_pos: 10, type_start_pos: 1, type_end_pos: 5),
          Arg.create(name: "arg2", type: "type2", start_pos: 13, end_pos: 22, name_start_pos: 19, name_end_pos: 22, type_start_pos: 13, type_end_pos: 17),
          Arg.create(name: "arg3", type: "type3", start_pos: 25, end_pos: 34, name_start_pos: 31, name_end_pos: 34, type_start_pos: 25, type_end_pos: 29)
        ]
        assert_equal expected, args.parse
      end
    end
  end
end
