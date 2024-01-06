# frozen_string_literal: true

require "test_helper"

class ReturnTypeParserTest < Minitest::Test
  def test_parse_no_return_type
    source_code = "def method_name"
    scanner = StringScanner.new(source_code)
    parens = Claret::Parsing::ParensParser.new(scanner)
    parser = Claret::Parsing::ReturnTypeParser.new(parens.parse)
    assert_equal Claret::Parsing::ReturnTypeParser::NoReturnTypeSpecified, parser.parse
  end

  def test_parse_has_return_type
    source_code = "def method_name => return_type"
    scanner = StringScanner.new(source_code)
    parens = Claret::Parsing::ParensParser.new(scanner)
    parser = Claret::Parsing::ReturnTypeParser.new(parens.parse)
    assert_equal Claret::Parsing::ReturnTypeParser::ReturnType.new("return_type", 19, 29, 16, 29), parser.parse
  end

  def test_parse_return_has_record_type_return_type
    source_code = "def method_name arg => { test: String }"
    scanner = StringScanner.new(source_code)
    parens = Claret::Parsing::ParensParser.new(scanner)
    parser = Claret::Parsing::ReturnTypeParser.new(parens.parse)
    assert_equal "{ test: String }", parser.parse.type
  end

  def test_parse_return_with_args_and_has_record_type_return_type
    source_code = "def method_name(type arg, test = -> { proc }, String b:, (Integer | String) x: 123) => { test: String }"
    scanner = StringScanner.new(source_code)
    parens = Claret::Parsing::ParensParser.new(scanner)
    parser = Claret::Parsing::ReturnTypeParser.new(parens.parse)
    assert_equal "{ test: String }", parser.parse.type
  end

  def test_parse_has_return_type_then_comment
    source_code = "def method_name => return type # comment"
    scanner = StringScanner.new(source_code)
    parens = Claret::Parsing::ParensParser.new(scanner)
    parser = Claret::Parsing::ReturnTypeParser.new(parens.parse)
    assert_equal Claret::Parsing::ReturnTypeParser::ReturnType.new("return type", 19, 29, 16, 30), parser.parse
  end

  def test_parse_has_complex_return_type
    source_code = "def method_name => ?(Type | OtherType[Type]) # comment"
    scanner = StringScanner.new(source_code)
    parens = Claret::Parsing::ParensParser.new(scanner)
    parser = Claret::Parsing::ReturnTypeParser.new(parens.parse)
    assert_equal Claret::Parsing::ReturnTypeParser::ReturnType.new("?(Type | OtherType[Type])", 19, 43, 16, 44), parser.parse
  end
end
