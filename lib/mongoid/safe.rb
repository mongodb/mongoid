# encoding: utf-8
module Mongoid #:nodoc:

  # Contains behaviour for determining if Mongoid is in safe mode.
  module Safe

    # Determine based on configuration if we are persisting in safe mode or
    # not.
    #
    # The query option will always override the global configuration.
    #
    # @example Are we in safe mode?
    #   document.safe_mode?(:safe => true)
    #
    # @param [ Hash ] options Persistence options.
    #
    # @return [ true, false ] True if in safe mode, false if not.
    def safe_mode?(options)
      safe = options[:safe]
      safe.nil? ? Mongoid.persist_in_safe_mode : safe
    end
  end
end
