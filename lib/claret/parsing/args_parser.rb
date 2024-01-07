# frozen_string_literal: true

module Claret
  module Parsing
    class ArgsParser
      include Claret::Utils::Logging

      def initialize(paren_group)
        @paren_group = paren_group
      end

      def parse
        group_paren_parts_into_args.map do |group|
          first_part, second_part, third_part = group[0..2]
          if group.size == 1 && arg_identifier?(first_part)
            create_arg_with_identifier(first_part, group[1..])
          elsif group.size == 2 && arg_identifier?(second_part)
            create_arg_with_identifier_and_type(first_part, second_part, group[2..])
          elsif group.size == 3 && first_part.paren_literal? && second_part.paren_group? && arg_identifier?(third_part) && first_part.match?(/\A\s*\?\z/)
            # Special case when "?" literal is before a type group
            optional_type = second_part.to_literal.prepend("?")
            optional_type = optional_type.with(start_pos: optional_type.start_pos - 1, end_pos: optional_type.end_pos - 1)
            create_arg_with_identifier_and_type(optional_type, third_part, group[3..])
          elsif arg_type_identifier_pair?(first_part)
            create_arg_with_identifier_and_type_pair(first_part, group[1..])
          elsif arg_identifier?(second_part)
            create_arg_with_identifier_and_type(first_part, second_part, group[2..])
          elsif arg_identifier?(first_part) && has_default?(first_part.append(group[1..].map(&:to_code).join)) # FIXME: has_default? is called twice on this branch
            create_arg_with_identifier(first_part, group[1..])
          else
            debug "Unknown argument that can not be parsed: #{group}"
            nil
          end
        end
      end

      private

      def create_arg_with_identifier(literal, rest_of_group)
        # If arg is optional, its type will be set as ?untyped
        arg_code = literal.append(rest_of_group.map(&:to_code).join)
        create_argument(literal, nil, arg_code)
      end

      def create_arg_with_identifier_and_type(type_group_or_literal, name_literal, rest_of_group)
        raise "The type is invalid" unless type_group_or_literal.paren_group? || literal_is_type?(type_group_or_literal)
        arg_code = type_group_or_literal.to_literal.append(name_literal).append(rest_of_group.map(&:to_code).join)
        create_argument(name_literal, type_group_or_literal, arg_code)
      end

      def create_arg_with_identifier_and_type_pair(literal, rest_of_group)
        type_literal, name_literal = literal.split(" ", 2)
        raise "This is not a type #{type_literal}" unless literal_is_type?(type_literal)
        arg_code = literal.append(rest_of_group.map(&:to_code).join)
        create_argument(name_literal, type_literal, arg_code)
      end

      def create_argument(name_literal, type_literal, arg_code)
        type = type_literal&.to_code
        name = clean_arg_identifier(name_literal)
        debug "Arg with identifier and type: '#{name}' is a '#{type || "untyped"}'"
        Arg.new(name:, type:, **arg_options(name_literal, arg_code, type), **arg_part_positions(arg_code, type_literal, name))
      end

      def arg_start_pos(item, name)
        item.start_pos + item.index(name)
      end

      def arg_end_pos(item, name)
        item.start_pos + item.index(name) + name.size - 1
      end

      def arg_part_positions(name_literal, type_literal, name)
        name_start = arg_start_pos(name_literal, name)
        name_end = name_start + name.size - 1
        {
          start_pos: type_literal&.start_pos || name_start,
          end_pos: name_end,
          name_start_pos: name_start,
          name_end_pos: name_end,
          type_start_pos: type_literal&.start_pos,
          type_end_pos: type_literal&.end_pos
        }
      end

      def arg_options(literal, arg_code, type)
        {
          method_arg_type: method_arg_type(literal),
          optional: type_optional_if_has_default(arg_code, type),
          ivar: arg_ivar?(literal)
        }
      end

      ARG_TYPE_MATCHER = "[\\s\\w_?:()&|\\[\\]{},]+"
      ARG_NAME_MATCHER = "[\\w_@]+"
      ARG_NAME_SUFFIXES = "[=:]|\\z"
      POSITIONAL_SUFFIXES = "=|\\z"
      KEYWORD_SUFFIXES = ":"

      def arg_identifier?(item)
        item.paren_literal? && item.match?(/^\s*(#{ARG_NAME_MATCHER})\s*(#{ARG_NAME_SUFFIXES})/o)
      end

      def arg_ivar?(item)
        item.match?(/^\s*@#{ARG_NAME_MATCHER}/o)
      end

      def clean_arg_identifier(item)
        item.match(/^\s*(#{ARG_NAME_MATCHER})\s*(#{ARG_NAME_SUFFIXES})/o).captures.first
      end

      def method_arg_type(name_literal)
        if name_literal.match?(/^\s*(#{ARG_NAME_MATCHER})\s*(#{POSITIONAL_SUFFIXES})/o)
          :positional
        elsif name_literal.match?(/^\s*(#{ARG_NAME_MATCHER})\s*(#{KEYWORD_SUFFIXES})/o)
          :keyword
        else
          raise "Unknown method arg type for #{name_literal}"
        end
      end

      def arg_type_identifier_pair?(item)
        item.paren_literal? && item.match(/^\s*(#{ARG_TYPE_MATCHER})\s+(#{ARG_NAME_MATCHER})\s*(#{ARG_NAME_SUFFIXES})/o)
      end

      def literal_is_type?(item)
        type = item.match(/^\s*(#{ARG_TYPE_MATCHER})\s*$/o)&.captures&.first
        return unless type
        # the type cannot include a single colon
        return if type.count(":") == 1
        type
      end

      def type_optional_if_has_default(arg_code, type = nil)
        return true if type&.strip&.start_with?("?")
        has_default?(arg_code)
      end

      def has_default?(arg_code)
        is_optional_positional = arg_code.match?(/\s*#{ARG_NAME_MATCHER}\s*=/o)
        is_optional_kwarg = arg_code.match?(/\s*#{ARG_NAME_MATCHER}\s*:\s*[^\s]+/o)
        is_optional_positional || is_optional_kwarg
      end

      # it should group by comma
      def group_paren_parts_into_args
        grouped = []
        @paren_group.each do |item|
          debug "Grouping item: #{item}"
          if item.paren_literal? && item.include?(",")
            segments = item.split(",", -1) # -1 to include empty segments
            debug "Split on comma: #{segments}"
            if grouped.empty?
              debug "after split comma, Appending as first arg: #{segments}"
              append_parts_as_args(grouped, segments)
            else
              debug "after split comma, Appending to last arg: #{segments[0]}"
              append_part_to_last_arg(grouped, segments[0])
              debug "after split comma, Appending parts as args: #{segments[1..]}"
              append_parts_as_args(grouped, segments[1..])
            end
          elsif grouped.empty?
            debug "Appending as first arg: #{[item]}"
            append_parts_as_args(grouped, [item])
          else
            debug "Appending to last arg: #{item} - #{grouped.last}"
            append_part_to_last_arg(grouped, item)
          end
        end
        # Remove any blank argument sections
        grouped.map { |group| group.reject { _1.blank? } }
      end

      def append_part_to_last_arg(grouped, segment)
        grouped.last.append(segment)
      end

      def append_parts_as_args(grouped, segments)
        grouped.concat segments.map { [_1] }
      end
    end
  end
end
