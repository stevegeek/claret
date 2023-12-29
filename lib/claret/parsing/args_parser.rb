# frozen_string_literal: true

module Claret
  module Parsing
    class ArgsParser
      include Claret::Utils::Logging

      def initialize(paren_group)
        @paren_group = paren_group
      end

      def parse
        group_parts.map do |group|
          group = group.reject { _1.blank? }

          first_part, second_part = group.first, group.last
          if group.size == 1 && arg_identifier?(first_part)
            name = clean_arg_identifier(first_part)
            debug "Arg with identifier: #{name}"
            start_pos = first_part.start_pos + first_part.index(name)
            end_pos = start_pos + name.size - 1
            Arg.new(name, nil, first_part.literal, start_pos, end_pos)
          elsif group.size == 2 && arg_identifier?(second_part)
            raise unless first_part.paren_group? || arg_type?(first_part)
            name = clean_arg_identifier(second_part)
            end_pos = second_part.start_pos + second_part.index(name) + name.size - 1
            type = first_part.to_code
            debug "Arg with identifier and type: #{name} - #{type}"
            Arg.new(name, type, second_part.literal, first_part.start_pos, end_pos)
          elsif arg_type_identifier_pair?(first_part)
            type_literal, name_literal, *_rest = first_part.split(" ")
            raise unless arg_type?(type_literal)
            name = clean_arg_identifier(name_literal)
            type = type_literal.to_code
            end_pos = name_literal.start_pos + name_literal.index(name) + name.size - 1
            debug "Arg with identifier and type: #{name} - #{type}"
            Arg.new(name, type, name_literal.literal, type_literal.start_pos, end_pos)
          end
        end
      end

      private

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
      def group_parts
        grouped = []
        @paren_group.each do |item|
          debug "Grouping item: '#{item}'"
          if item.paren_literal? && item.include?(",")
            segments = item.split(",", -1) # -1 to include empty segments
            if grouped.empty?
              grouped = segments.map { [_1] }
            else
              grouped[-1] << segments[0]
              grouped.concat segments[1..].map { [_1] }
            end
          elsif grouped.empty?
            grouped = [[item]]
          else
            grouped[-1] << item
          end
        end
        grouped
      end
    end
  end
end
