module Mongoid

  class LogSubscriber < ActiveSupport::LogSubscriber
    def query(event)
      return unless logger.debug?

      payload = event.payload
      runtime = ("%.4fms" % event.duration)
      debug(payload[:prefix], payload[:ops], runtime)
    end

    def debug(prefix, operations, runtime)
      Moped::Loggable.log_operations(prefix, operations, runtime)
    end

    def logger
      Moped.logger
    end
  end
end

Mongoid::LogSubscriber.attach_to :moped
