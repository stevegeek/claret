# frozen_string_literal: true

require "forwardable"

module Claret
  module Parsing
    class EndlessGreedyLiteral < GreedyLiteral
      def paren_literal?
        false
      end
    end
  end
end
