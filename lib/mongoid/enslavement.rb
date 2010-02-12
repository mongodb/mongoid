# encoding: utf-8
module Mongoid #:nodoc:
  module Enslavement #:nodoc:
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        class_inheritable_accessor :enslaved
        self.enslaved = false

        delegate :enslaved?, :to => "self.class"
      end
    end

    module ClassMethods #:nodoc
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
        self.enslaved == true
      end
    end
  end
end
