# encoding: utf-8
module Mongoid #:nodoc
  module Indexes #:nodoc
    extend ActiveSupport::Concern
    included do
      cattr_accessor :index_options
      self.index_options = {}
    end

    module ClassMethods #:nodoc

      # Send the actual index creation comments to the MongoDB driver
      def create_indexes
        return unless index_options
        current_collection = self._collection || set_collection
        index_options.each do |name, options|
          current_collection.create_index(name, options)
        end
      end

      # Add the default indexes to the root document if they do not already
      # exist. Currently this is only _type.
      def add_indexes
        if hereditary? && !index_options[:_type]
          self.index_options[:_type] = {:unique => false, :background => true}
        end
        create_indexes if Mongoid.autocreate_indexes
      end

      # Adds an index on the field specified. Options can be :unique => true or
      # :unique => false. It will default to the latter.
      def index(name, options = { :unique => false })
        self.index_options[name] = options
        create_indexes if Mongoid.autocreate_indexes
      end
    end
  end
end
