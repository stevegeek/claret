module Claret
  module Generating
    class SigComment
      def initialize(args, return_type)
        @args = args
        @return_type = return_type
      end

      def generate
        arg_sig = @args&.map do |arg|
          str = if arg.positional?
            "#{arg.type} #{arg.name}"
          else
            "#{arg.name}: #{arg.type}"
          end
          (arg.optional? && !str.start_with?("?")) ? "?#{str}" : str
        end
        "# @sig (#{arg_sig&.join(", ")}) -> #{@return_type}"
      end
    end
  end
end
