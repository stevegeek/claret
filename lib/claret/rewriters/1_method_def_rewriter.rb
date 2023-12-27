require "strscan"

require_relative "../utils/logging"
require_relative "../parsing/parens"

module Claret
  module Rewriters
    class MethodDefRewriter < RubyNext::Language::Rewriters::Text
      include ::Claret::Utils::Logging

      NAME = "claret-positional-arg-type"
      SYNTAX_PROBE = "def foo(String a, (Integer | String) b, customType c, ivarType @ivar)"
      MIN_SUPPORTED_VERSION = Gem::Version.new(RubyNext::NEXT_VERSION)

      def safe_rewrite(source)
        modified_source = source.dup

        source.scan(/(def\s+[\w_]+)(.*)$/).each do |method_def_match|
          debug "> Method def match: #{method_def_match.inspect}"
          matched_def = method_def_match.join
          scanner = StringScanner.new matched_def
          stack = Claret::Parsing::Parens.new(scanner).parse

          # TODO: we still need to handle return values
          if stack.size < 2
            add_sig_comment(modified_source, method_def_match, [])
            next
          end

          debug "> Parsed arguments:"
          debug stack.inspect

          types = stack.last.map do |arg_def|
            debug "> Arg def: #{arg_def}"

            to_replace, type, arg = if arg_def.is_a?(String) && arg_def.match?(/[\w_]+\s+[\w_@=]+\s*/)
              optional = arg_def.include?("=")
              arg_def = arg_def.split("=").first
              debug "> Arg def simple: #{arg_def}"

              type, arg = arg_def.squeeze(" ").strip.split(" ")
              type_for_sig = optional ? "?(#{type})" : type
              [arg_def, type_for_sig, arg]
            elsif arg_def.is_a?(Array)
              # TODO: handle nested parens in type
              type = arg_def.first.first
              arg = arg_def[1]
              optional = arg.include?("=")
              type_for_sig = optional ? "?(#{type})" : type
              [/\(\s*#{Regexp.escape(type)}\s*\)\s*#{Regexp.escape(arg)}/, type_for_sig, arg]
            else
              raise "Unexpected arg def: #{arg_def}"
            end

            debug "> Replace: #{to_replace} -- (Type: #{type}, Arg: #{arg})"

            modified_source.gsub!(to_replace, arg)
            type
          end

          # Mark file dirty
          context.track! self

          # TODO: handle return type
          add_sig_comment(modified_source, method_def_match, types)
        end

        modified_source
      end

      private

      def add_sig_comment(source, method_def_match, types)
        method = method_def_match.first
        sig_comment = "# @sig (#{types.join(", ")}) -> void"
        debug "> Add sig comment to '#{method}': #{sig_comment}"
        # Ensure to capture whole of line and add comment at end
        source.gsub!(/#{method}(.*)$/, "#{method}\\1 #{sig_comment}")
      end
    end
  end
end

# Add the rewriter to the list of rewriters
RubyNext::Language.rewriters << Claret::Rewriters::MethodDefRewriter
