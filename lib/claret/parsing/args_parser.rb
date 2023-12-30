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
            create_arg_with_identifier(first_part)
          elsif group.size == 2 && arg_identifier?(second_part)
            create_arg_with_identifier_and_type(first_part, second_part)
          elsif group.size == 3 && first_part.paren_literal? && second_part.paren_group? && arg_identifier?(third_part) && first_part.match?(/\A\s*\?\s*\z/)
            # Special case when "?" literal is before a type group
            optional_type = second_part.to_literal.prepend("?")
            create_arg_with_identifier_and_type(optional_type, third_part)
          elsif arg_type_identifier_pair?(first_part)
            create_arg_with_identifier_and_type_pair(first_part)
          else
            debug "Unknown argument that can not be parsed: #{group}"
            nil
          end
        end
      end

      private

      def create_arg_with_identifier(literal)
        name = clean_arg_identifier(literal)
        debug "Arg with identifier: #{name}"
        # If arg is optional, its type will be set as ?untyped
        create_argument(
          name,
          make_type_optional_if_has_default(literal),
          literal,
          arg_start_pos(literal, name),
          arg_end_pos(literal, name)
        )
      end

      def create_arg_with_identifier_and_type(type_group_or_literal, name_literal)
        raise "The type is invalid" unless type_group_or_literal.paren_group? || literal_is_type?(type_group_or_literal)
        name = clean_arg_identifier(name_literal)
        type = make_type_optional_if_has_default(name_literal, type_group_or_literal.to_code)
        debug "Arg with identifier and type: #{name} - #{type}"
        create_argument(name, type, name_literal, type_group_or_literal.start_pos, arg_end_pos(name_literal, name))
      end

      def create_arg_with_identifier_and_type_pair(literal)
        type_literal, name_literal = literal.split(" ", 2)
        raise unless literal_is_type?(type_literal)
        name = clean_arg_identifier(name_literal)
        type = make_type_optional_if_has_default(name_literal, type_literal.to_code)
        debug "Arg with identifier and type: '#{name}' is a '#{type}'"
        create_argument(name, type, name_literal, type_literal.start_pos, arg_end_pos(name_literal, name))
      end

      def create_argument(name, type, name_literal, start_pos, end_pos)
        Arg.new(name, type, name_literal.literal, start_pos, end_pos)
      end

      def arg_start_pos(item, name)
        item.start_pos + item.index(name)
      end

      def arg_end_pos(item, name)
        item.start_pos + item.index(name) + name.size - 1
      end

      ARG_TYPE_MATCHER = "[\\s\\w_?:()&|\\[\\]{},]+"
      ARG_NAME_MATCHER = "[\\w_@]+"
      ARG_NAME_SUFFIXES = "[=:]|\\z"

      def arg_identifier?(item)
        item.paren_literal? && item.match?(/^\s*(#{ARG_NAME_MATCHER})\s*(#{ARG_NAME_SUFFIXES})/o)
      end

      def clean_arg_identifier(item)
        item.match(/^\s*(#{ARG_NAME_MATCHER})\s*(#{ARG_NAME_SUFFIXES})/o).captures.first
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

      # TODO: refactor out the parsing of type information to a separate class
      def make_type_optional_if_has_default(literal, type = nil)
        return type if type&.strip&.start_with?("?")
        is_optional_positional = literal.match?(/^\s*#{ARG_NAME_MATCHER}\s*=/o)
        is_optional_kwarg = literal.match?(/:\s*[\w_@]+/)
        (is_optional_positional || is_optional_kwarg) ? "?#{type || "untyped"}" : type
      end

      # it should group by comma
      def group_paren_parts_into_args
        grouped = []
        @paren_group.each do |item|
          if item.paren_literal? && item.include?(",")
            segments = item.split(",", -1) # -1 to include empty segments
            if grouped.empty?
              append_parts_as_args(grouped, segments)
            else
              append_part_to_last_arg(grouped, segments[0])
              append_parts_as_args(grouped, segments[1..])
            end
          elsif grouped.empty?
            append_parts_as_args(grouped, [item])
          else
            append_part_to_last_arg(grouped, item)
          end
        end
        # Remove any blank argument sections
        grouped.map { |group| group.reject { _1.blank? } }
      end

      def append_part_to_last_arg(grouped, segment)
        grouped[-1] << segment
      end

      def append_parts_as_args(grouped, segments)
        grouped.concat segments.map { [_1] }
      end
    end
  end
end
