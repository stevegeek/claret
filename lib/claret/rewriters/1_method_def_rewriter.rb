require "strscan"

require_relative "../required"

module Claret
  module Rewriters
    class MethodDefRewriter < RubyNext::Language::Rewriters::Text
      include ::Claret::Utils::Logging

      NAME = "claret-positional-arg-type"
      SYNTAX_PROBE = "def foo(String a, (Integer | String) b, customType c, ivarType @ivar)"
      MIN_SUPPORTED_VERSION = Gem::Version.new(RubyNext::NEXT_VERSION)

      def safe_rewrite(source)
        modified_source = source.dup

        # TODO: this could be done less ugly
        source.scan(/^(\s*)(def\s+[\w_]+)(.*)$/).each do |method_def_match|
          debug "Method def match: #{method_def_match.inspect}"
          matched_def = method_def_match.join
          modified_def = matched_def.dup
          parsed_def = Claret::Parsing::MethodDefParser.new(matched_def).parse

          # TODO: refactor
          # Remove arguments type info
          parsed_def[:args]&.each do |arg|
            debug "Removing type info for arg: #{arg.inspect}  (in #{modified_def})"
            next unless arg.type_start_pos && arg.type_end_pos
            length = 1 + arg.type_end_pos - arg.type_start_pos
            replace_substring_in_source(modified_def, arg.type_start_pos, arg.type_end_pos, " " * length)
          end

          # Remove ivar prefixes from args
          ivar_args = remove_ivar_prefixes(modified_def, parsed_def[:args])

          # Remove return type
          return_type = parsed_def[:return_type]
          if return_type.sig_start_pos && return_type.sig_end_pos
            debug "Removing type info for return type: #{return_type.inspect} (in #{modified_def})"
            length = 1 + return_type.sig_end_pos - return_type.sig_start_pos
            replace_substring_in_source(modified_def, return_type.sig_start_pos, return_type.sig_end_pos, " " * length)
          end

          # Replace method def with modified one in output Ruby
          debug "Replacing '#{matched_def}' with '#{modified_def}'"
          modified_source.gsub!(matched_def, modified_def)

          # Add the sig comment
          add_sig_comment(modified_source, method_def_match, parsed_def[:args], parsed_def[:return_type].type)
          # Add this setters
          add_method_ivars_setters(modified_source, method_def_match, ivar_args) if ivar_args
        end

        # Mark file dirty
        context.track! self

        modified_source
      end

      private

      def remove_ivar_prefixes(modified_def, args)
        args&.filter(&:ivar?)&.each do |arg|
          debug "Removing ivar prefix for arg: #{arg.name}"
          replace_substring_in_source(modified_def, arg.name_start_pos, arg.name_end_pos, " #{arg.ruby_name}")
        end
      end

      def add_sig_comment(source, method_def_match, args, return_type)
        method = method_def_match[1]
        sig_comment = ::Claret::Generating::SigComment.new(args, return_type).generate
        debug "Add sig comment to '#{method}': #{sig_comment}"
        source.gsub!(/#{method}(.*)$/, "#{method}\\1 #{sig_comment}")
      end

      def add_method_ivars_setters(source, method_def_match, ivar_args)
        method = method_def_match[1]
        indent = method_def_match[0]

        setters = ivar_args.map do |arg|
          "#{arg.name} = #{arg.ruby_name}"
        end

        return if setters.nil? || setters.empty?
        # Now add setters to the end of the method
        setters_code = "\n#{indent}  #{setters.join("\n#{indent}  ")}"

        debug "Add setters to '#{method}'"
        source.gsub!(/#{method}(.*)$/, "#{method}\\1#{setters_code}")
      end

      def replace_substring_in_source(source, from, to, replacement)
        debug "Replace from #{from} to #{to} ('#{source[from..to]}' with '#{replacement}')"
        source[from..to] = replacement
      end
    end
  end
end

# Add the rewriter to the list of rewriters
RubyNext::Language.rewriters << Claret::Rewriters::MethodDefRewriter
