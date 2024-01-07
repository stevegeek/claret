# frozen_string_literal: true

module Claret
  module Parsing
    class MethodDefParser
      include ::Claret::Utils::Logging

      def initialize(source_code)
        @source_code = source_code
        @scanner = StringScanner.new source_code
      end

      attr_reader :scanner

      def parse
        parens = ParensParser.new(@scanner).parse

        debug "Parsed parens: #{parens}"

        method_def_item = parens.first
        raise "Input does not look like a method definition" unless method_def_item.paren_literal? && method_def_item.include?("def")

        name = method_def_item.split("def").last.to_code.strip

        debug "Parsed method name: #{name}"

        # Now get the arguments, we assume for now you must wrap them in parens
        arguments = parens[1..].find(&:paren_group?)
        debug "Parsing as arguments: #{arguments}"
        args = ArgsParser.new(arguments).parse if arguments && !arguments.blank?
        debug "Parsed args: #{args}"

        return_type = ReturnTypeParser.new(parens).parse
        debug "Parsed return type: #{return_type}"

        {
          name: name,
          args: args,
          return_type: return_type
        }
      end
    end
  end
end
