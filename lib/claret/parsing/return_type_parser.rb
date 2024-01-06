# frozen_string_literal: true

module Claret
  module Parsing
    class ReturnTypeParser
      include ::Claret::Utils::Logging

      ReturnType = Data.define(:type, :start_pos, :end_pos, :sig_start_pos, :sig_end_pos)
      NoReturnTypeSpecified = ReturnType.new("void", nil, nil, nil, nil)

      def initialize(paren_groups)
        @paren_groups = paren_groups
      end

      # the return type is after the '=>' until the end of the line.
      def parse
        debug "Extracting return type from: #{segments_of_return_type.inspect}"
        found_type = return_type_from_signature
        unless found_type && found_type[0]
          debug "No return type found - defaulting to 'void'"
          return NoReturnTypeSpecified
        end
        ReturnType.new(**type_and_offsets_of_return_type(found_type))
      end

      private

      def return_type_from_signature
        return unless segments_of_return_type
        type_source = segments_of_return_type.map(&:to_code).join
        type_source.match(/=>\s*(.*)(?<!\s)/)
      end

      # We look only at last of the top level of parsed literals for the return type, as it won't be nested
      def segments_of_return_type
        @segments_of_return_type ||= begin
          start_index = start_of_signature
          return unless start_index
          end_index = end_of_signature
          @paren_groups[start_index...end_index]
        end
      end

      def start_of_signature
        @paren_groups.rindex { _1.paren_literal? && _1.include?("=>") }
      end

      def end_of_signature
        (@paren_groups.rindex { _1.is_a?(EndlessGreedyLiteral) }) ? -1 : nil
      end

      def type_and_offsets_of_return_type(match)
        start_offset = sig_start_offset
        found_at = match.begin(0)
        type_found_at = match.begin(1)
        type = match[1]
        type_found_end = type_found_at + type.size - 1
        debug "Found return type: #{type} at #{type_found_at} - #{type_found_end}"
        {
          type: type,
          start_pos: start_offset + type_found_at,
          end_pos: start_offset + type_found_end,
          sig_start_pos: start_offset + found_at,
          sig_end_pos:
        }
      end

      def sig_start_offset
        segments_of_return_type.first.start_pos
      end

      def sig_end_pos
        segments_of_return_type.last.end_pos
      end
    end
  end
end
