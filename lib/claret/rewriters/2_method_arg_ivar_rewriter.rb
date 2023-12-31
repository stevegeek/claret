require "strscan"

require_relative "../required"

module Claret
  module Rewriters
    class MethodArgIvarRewriter < RubyNext::Language::Rewriters::Text
      include ::Claret::Utils::Logging

      NAME = "claret-ivar-arg"
      # Must be run after the MethodDefRewriter
      SYNTAX_PROBE = "def foo(@a, @b, @c = :foo)"
      MIN_SUPPORTED_VERSION = Gem::Version.new(RubyNext::NEXT_VERSION)

      def safe_rewrite(source)
        modified_source = source.dup

        source.scan(/(def\s+[\w_]+\s*)([^#]*)/).each do |method_def_match|
          debug "> Method def match: #{method_def_match.inspect}"

          method_def_match = method_def_match.join
          scanner = StringScanner.new method_def_match
          stack = Claret::Parsing::Parens.new(scanner).parse

          next if stack.size < 2

          debug "> Parsing arguments:"
          debug stack.inspect

          ivars_lines = stack.last.map do |arg_def|
            debug "> Arg def: #{arg_def}"
            arg_str = if arg_def.is_a?(String)
              arg_def = arg_def.strip
              if arg_def[0] == "@"
                debug "> ivar def: #{arg_def}"
                arg_def[1..-1]
              end
            elsif arg_def.is_a?(Array) && arg_def.first
              arg_def = arg_def.first.strip
              if arg_def[0] == "@"
                debug "> ivar def: #{arg_def}"
                arg_def.first[1..-1]
              end
            end
            next unless arg_str
            arg_name = arg_str.match(/[\w_]+/).to_s

            debug "> Set: @#{arg_name}"

            modified_source.gsub!(arg_def, arg_def[1..-1])
            method_def_match.gsub!(arg_def, arg_def[1..-1])
            "@#{arg_name} = #{arg_name}"
          end

          ivars_lines.compact!

          # Mark file dirty
          context.track! self

          debug "> Add setters: #{ivars_lines.join("\n")}"
          # Ensure to capture whole of line inc comments and then add ivar lines at end
          modified_source.gsub!(/#{Regexp.escape(method_def_match)}(.*)$/, "#{method_def_match}\\1#{ivars_lines.map { "\n#{_1}" }.join}")
        end

        modified_source
      end
    end
  end
end

# Add the rewriter to the list of rewriters
RubyNext::Language.rewriters << Claret::Rewriters::MethodArgIvarRewriter
