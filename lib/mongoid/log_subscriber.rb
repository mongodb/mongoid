module Mongoid

  class LogSubscriber < ActiveSupport::LogSubscriber
    def query(event)
      payload = event.payload
      runtime = ("%.4fms" % event.duration)
      Moped::Loggable.log_operations(payload[:prefix], payload[:ops], runtime)
    end

    def logger
      Moped.logger
    end
  end
end

Mongoid::LogSubscriber.attach_to :moped
