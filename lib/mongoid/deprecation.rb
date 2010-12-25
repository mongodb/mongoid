# encoding: utf-8
module Mongoid #:nodoc:
  module Deprecation #:nodoc
    extend self

    # Alert of a deprecation. This will delegate to the logger and call warn on
    # it.
    #
    # Example:
    #
    # <tt>deprecation.alert("Method no longer used")</tt>
    def alert(message)
      logger.warn("Deprecation: #{message}")
    end

    protected
    def logger
      @logger ||= Mongoid::Logger.new
    end
  end
end
