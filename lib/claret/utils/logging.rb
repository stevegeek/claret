require "logger"

module Claret
  module Utils
    module Logging
      def say(msg)
        logger.info("#{self.class.name} > #{msg}")
      end

      def debug(msg)
        logger.debug("#{self.class.name} > #{msg}")
      end

      def logger
        @logger ||= ::Logger.new($stdout, level: ENV.fetch("DEBUG", "").empty? ? Logger::INFO : Logger::DEBUG)
      end
    end
  end
end
