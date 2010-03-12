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
    # Instantiate a new logger to stdout or a rails logger if available.
    def initialize
      @logger = Logger.new($stdout)
    end
  end
end
