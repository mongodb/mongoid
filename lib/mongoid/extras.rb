# encoding: utf-8
module Mongoid #:nodoc:

  # Adds support for caching queries at the class level.
  module Extras
    extend ActiveSupport::Concern

    included do
      class_attribute :cached
      self.cached = false
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
    end
  end
end
