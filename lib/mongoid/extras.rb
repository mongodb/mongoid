# encoding: utf-8
module Mongoid #:nodoc:

  # Adds support for caching queries at the class level.
  module Extras
    extend ActiveSupport::Concern

    included do
      class_attribute :cached
      self.cached = false
      delegate :cached?, :to => "self.class"
    end

    module ClassMethods #:nodoc

      # Sets caching on for this class. This class level configuration will
      # default all queries to cache the results of the first iteration over
      # the cursor into an internal array. This should only be used for queries
      # that return a small number of results or have small documents, as after
      # the first iteration the entire results will be stored in memory.
      #
      # @example Cache all reads for the class.
      #   class Person
      #     include Mongoid::Document
      #     cache
      #   end
      def cache
        self.cached = true
      end

      # Determines if the class is cached or not.
      #
      # @example Are class reads cached?
      #   Document.cached?
      #
      # @return [ true, false ] If the reads are cached.
      def cached?
        !!self.cached
      end
    end
  end
end
