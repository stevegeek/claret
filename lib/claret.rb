# frozen_string_literal: true

require_relative "claret/version"

require "ruby-next/language"
require "ruby-next/language/rewriters/text"

require_relative "claret/required"

require_relative "claret/rewriters/1_method_def_rewriter"

module Claret
  class Error < StandardError; end
  # Your code goes here...
end
