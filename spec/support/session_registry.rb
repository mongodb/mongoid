require 'singleton'

module Mongo
  class Client
    alias :get_session_without_tracking :get_session

    def get_session(options = {})
      get_session_without_tracking(options).tap do |session|
        SessionRegistry.instance.register(session)
      end
    end
  end
end

class SessionRegistry
  include Singleton

  def initialize
    @registry = []
  end

  def register(session)
    @registry << session if session
  end

  def verify_sessions_ended!
    @registry.reject! { |session| session.ended? }

    unless @registry.empty?
      raise "Session registry contains live sessions: #{@registry.join(', ')}"
    end
  end

  def clear_registry
    @registry = []
  end
end
