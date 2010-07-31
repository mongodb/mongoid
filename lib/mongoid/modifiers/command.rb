# encoding: utf-8
module Mongoid #:nodoc:
  module Modifiers #:nodoc:
    class Command #:nodoc:

      # Instantiate the new $inc modifier.
      #
      # Options:
      #
      # klass: The class to get the collection from.
      # options: The options to get passed through to the driver.
      def initialize(document, options = {})
        @document, @options = document, options
      end

      protected
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
end
