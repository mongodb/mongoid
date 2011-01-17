# encoding: utf-8
module Mongoid #:nodoc:
  module Extras #:nodoc:
    extend ActiveSupport::Concern
    included do
      class_attribute :cached, :enslaved
      self.cached = false
      self.enslaved = false
      delegate :cached?, :enslaved?, :to => "self.class"
    end

    module ClassMethods #:nodoc
      # Sets caching on for this class. This class level configuration will
      # default all queries to cache the results of the first iteration over
      # the cursor into an internal array. This should only be used for queries
      # that return a small number of results or have small documents, as after
      # the first iteration the entire results will be stored in memory.
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
        !!self.cached
      end

      # Set whether or not this documents read operations should delegate to
      # the slave database by default.
      #
      # Example:
      #
      #   class Person
      #     include Mongoid::Document
      #     enslave
      #   end
      def enslave
        self.enslaved = true
      end

      # Determines if the class is enslaved or not.
      #
      # Returns:
      #
      # True if enslaved, false if not.
      def enslaved?
        !!self.enslaved
      end
    end
  end
end
