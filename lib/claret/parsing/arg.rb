# frozen_string_literal: true

module Claret
  module Parsing
    Arg = Data.define(:name, :type, :start_pos, :end_pos, :name_start_pos, :name_end_pos, :type_start_pos, :type_end_pos, :method_arg_type, :optional, :ivar) do
      def self.create(name:, type:, start_pos:, end_pos:, name_start_pos:, name_end_pos:, type_start_pos: nil, type_end_pos: nil, method_arg_type: :positional, optional: false, ivar: false)
        new(
          name:,
          type:,
          start_pos:,
          end_pos:,
          name_start_pos:,
          name_end_pos:,
          type_start_pos:,
          type_end_pos:,
          method_arg_type:,
          optional:,
          ivar:
        )
      end

      def ruby_name
        name.tr("@", "")
      end

      def positional?
        method_arg_type == :positional
      end

      def keyword?
        method_arg_type == :keyword
      end

      def optional?
        optional
      end

      def ivar?
        ivar
      end
    end
  end
end
