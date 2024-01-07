# frozen_string_literal: true

require "test_helper"
require "claret/parsing/method_def_parser"

module Claret
  module Parsing
    class MethodDefParserTest < Minitest::Test
      def test_parse_method_name
        source = "def test(foo)"
        parsed = Claret::Parsing::MethodDefParser.new(source)
        assert_equal "test", parsed.parse[:name]
      end

      def test_parse_method
        source = "def test(String hello, ?(Integer | customType) foo = 1, kwarg: \"))((\") => String # comment"
        parsed = Claret::Parsing::MethodDefParser.new(source)
        expected_result = {
          name: "test",
          args: [
            Arg.create(name: "hello", type: "String", start_pos: 9, end_pos: 20, name_start_pos: 16, name_end_pos: 20, type_start_pos: 9, type_end_pos: 14, method_arg_type: :positional),
            Arg.create(name: "foo", type: "?(Integer | customType)", start_pos: 23, end_pos: 49, name_start_pos: 47, name_end_pos: 49, type_start_pos: 23, type_end_pos: 45, optional: true, method_arg_type: :positional),
            Arg.create(name: "kwarg", type: nil, start_pos: 56, end_pos: 60, name_start_pos: 56, name_end_pos: 60, optional: true, method_arg_type: :keyword)
          ],
          return_type: Claret::Parsing::ReturnTypeParser::ReturnType.new(
            type: "String",
            start_pos: 74,
            end_pos: 79,
            sig_start_pos: 71,
            sig_end_pos: 80
          )
        }
        assert_equal expected_result, parsed.parse
      end
    end
  end
end
