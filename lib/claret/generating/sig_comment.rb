module Claret
  module Generating
    class SigComment
      def initialize(args, return_type)
        @args = args
        @return_type = return_type
      end

      def generate
        arg_sig = @args&.map do |arg|
          str = if arg.positional? && arg.type
            "#{arg.type} #{arg.ruby_name}"
          elsif arg.positional?
            arg.ruby_name
          elsif arg.keyword? && arg.type
            "#{arg.ruby_name}: #{arg.type}"
          elsif arg.keyword?
            "#{arg.ruby_name}:"
          end
          (arg.optional? && !str.start_with?("?")) ? "?#{str}" : str
        end
        "# @sig (#{arg_sig&.join(", ")}) -> #{@return_type}"
      end
    end
  end
end
