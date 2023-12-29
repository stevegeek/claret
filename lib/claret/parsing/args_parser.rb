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
          first_part, second_part = group.first, group.last
          if group.size == 1 && arg_identifier?(first_part)
            create_arg_with_identifier(first_part)
          elsif group.size == 2 && arg_identifier?(second_part)
            create_arg_with_identifier_and_type(first_part, second_part)
          elsif arg_type_identifier_pair?(first_part)
            create_arg_with_identifier_and_type_pair(first_part)
          end
        end
      end

      private

      def create_arg_with_identifier(literal)
        name = clean_arg_identifier(literal)
        debug "Arg with identifier: #{name}"
        create_argument(name, nil, literal, arg_start_pos(literal, name), arg_end_pos(literal, name))
      end

      def create_arg_with_identifier_and_type(type_group, name_literal)
        raise unless type_group.paren_group? || arg_type?(type_group)
        name = clean_arg_identifier(name_literal)
        type = type_group.to_code
        debug "Arg with identifier and type: #{name} - #{type}"
        create_argument(name, type, name_literal, type_group.start_pos, arg_end_pos(name_literal, name))
      end

      def create_arg_with_identifier_and_type_pair(literal)
        type_literal, name_literal, *_rest = literal.split(" ")
        raise unless arg_type?(type_literal)
        name = clean_arg_identifier(name_literal)
        type = type_literal.to_code
        debug "Arg with identifier and type: #{name} - #{type}"
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

      def clean_arg_identifier(item)
        item.match(/^\s*([\w_@]+)\s*([=:]|\z)/).captures.first
      end

      def arg_identifier?(item)
        item.paren_literal? && item.match?(/^\s*([\w_@]+)\s*([=:]|\z)/)
      end

      def arg_type_identifier_pair?(item)
        item.paren_literal? && item.match(/^\s*([\w_]+)\s+([\w_@]+)\s*([=:]|\z)/)
      end

      def arg_type?(item)
        item.match?(/^\s*[\w_]+\s*$/)
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
