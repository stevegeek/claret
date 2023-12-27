# frozen_string_literal: true

require "test_helper"
require "claret/parsing/parens"

class ParensTest < Minitest::Test
  def setup
  end

  def test_parse
    scanner = StringScanner.new("(hello, (world) test, with (nested (parens))")
    parens = Claret::Parsing::Parens.new(scanner)
    expected_result = [["hello", [["world"], "test", ["with", ["nested", ["parens"]]]]]]
    assert_equal expected_result, parens.parse
  end

  def test_one_arg
    scanner = StringScanner.new("(Type hello)")
    parens = Claret::Parsing::Parens.new(scanner)
    expected_result = [["Type hello"]]
    assert_equal expected_result, parens.parse
  end

  def test_parse_args_no_types
    scanner = StringScanner.new("(@hello, world = :foo, @test: (@var + 4)")
    parens = Claret::Parsing::Parens.new(scanner)
    expected_result = [["@hello", ["world = :foo", ["@test:", ["@var + 4"]]]]]
    assert_equal expected_result, parens.parse
  end
end
