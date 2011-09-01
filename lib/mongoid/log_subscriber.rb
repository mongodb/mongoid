module Mongoid
  class LogSubscriber < ActiveSupport::LogSubscriber
    def self.runtime=(value)
      Thread.current["mongoid_runtime"] = value
    end

    def self.runtime
      Thread.current["mongoid_runtime"] ||= 0
    end

    def self.reset_runtime
      rt, self.runtime = runtime, 0
      rt
    end

    def initialize
      super
      @odd_or_even = false
    end

    def db(event)
      self.class.runtime += event.duration
      return unless logger.debug?

      event_payload = event.payload
      payload = event_payload[:payload]

      name = '%s (%.1fms)' % [payload[:collection], event.duration]

      msg = "#{payload[:database]}['#{payload[:collection]}'].#{event_payload[:name]}("
      msg += payload.values_at(:selector, :document, :documents, :fields ).compact.map(&:inspect).join(', ') + ")"
      msg += ".skip(#{payload[:skip]})"  if payload[:skip]
      msg += ".limit(#{payload[:limit]})"  if payload[:limit]
      msg += ".sort(#{payload[:order]})"  if payload[:order]

      if odd?
        name   = color(name, CYAN, true)
        query  = color(query, nil, true)
      else
        name = color(name, MAGENTA, true)
      end

      debug "  #{name}  #{msg}"
    end

    def odd?
      @odd_or_even = !@odd_or_even
    end

    def logger
      Mongoid.logger
    end
  end
end

Mongoid::LogSubscriber.attach_to :mongoid
