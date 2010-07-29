module Mongoid
  class Logger

    delegate :info, :debug, :error, :fatal, :unknown, :to => :logger, :allow_nil => true

    def warn(message)
      logger.warn(message) if logger && logger.respond_to?(:warn)
    end

    def logger
      Mongoid.logger
    end

    def inspect
      "#<Mongoid::Logger:0x#{object_id.to_s(16)} @logger=#{logger.inspect}>"
    end
  end
end
