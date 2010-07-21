# encoding: utf-8
module Mongoid #:nodoc:
  class Deprecation #:nodoc
    include Singleton

    # Alert of a deprecation. This will delegate to the logger and call warn on
    # it.
    #
    # Example:
    #
    # <tt>deprecation.alert("Method no longer used")</tt>
    def alert(message)
      @logger.warn("Deprecation: #{message}")
    end

    protected
    def initialize
      @logger = Mongoid::Logger.new
    end
  end
end
