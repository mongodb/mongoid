# encoding: utf-8
module Mongoid #:nodoc
  module Indexes #:nodoc
    def self.included(base)
      base.class_eval do
        extend ClassMethods

        cattr_accessor :indexed
        self.indexed = false
      end
    end

    module ClassMethods #:nodoc
      # Add the default indexes to the root document if they do not already
      # exist. Currently this is only _type.
      def add_indexes
        unless indexed
          self._collection.create_index(:_type, false)
          self.indexed = true
        end
      end

      # Adds an index on the field specified. Options can be :unique => true or
      # :unique => false. It will default to the latter.
      def index(name, options = { :unique => false })
        collection.create_index(name, options[:unique])
      end
    end
  end
end
