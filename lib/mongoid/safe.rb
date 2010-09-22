# encoding: utf-8
module Mongoid #:nodoc:
  module Safe #:nodoc:
    # Determine based on configuration if we are persisting in safe mode or
    # not.
    #
    # The query option will always override the global configuration.
    def safe_mode?(options)
      safe = options[:safe]
      safe.nil? ? Mongoid.persist_in_safe_mode : safe
    end
  end
end
