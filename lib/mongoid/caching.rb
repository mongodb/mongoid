# encoding: utf-8
module Mongoid #:nodoc:
  module Caching #:nodoc:
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        class_inheritable_accessor :cached
        self.cached = false

        delegate :cached?, :to => "self.class"
      end
    end

    module ClassMethods #:nodoc
      # Sets caching on for this class.
      #
      # Example:
      #
      #   class Person
      #     include Mongoid::Document
      #     cache
      #   end
      def cache
        self.cached = true
      end

      # Determines if the class is cached or not.
      #
      # Returns:
      #
      # True if cached, false if not.
      def cached?
        self.cached == true
      end
    end
  end
end
