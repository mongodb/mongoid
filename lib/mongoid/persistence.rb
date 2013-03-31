# encoding: utf-8
require "mongoid/persistence/atomic"
require "mongoid/persistence/upsertion"
require "mongoid/persistence/operations"

module Mongoid

  # The persistence module is a mixin to provide database accessor methods for
  # the document. These correspond to the appropriate accessors on a
  # mongo collection and retain the same DSL.
  #
  # @example Sample persistence operations.
  #   document.insert
  #   document.update
  #   document.upsert
  module Persistence
    extend ActiveSupport::Concern
    include Atomic
    include Mongoid::Atomic::Positionable

    # Perform an upsert of the document. If the document does not exist in the
    # database, then Mongo will insert a new one, otherwise the fields will get
    # overwritten with new values on the existing document.
    #
    # @example Upsert the document.
    #   document.upsert
    #
    # @param [ Hash ] options The validation options.
    #
    # @return [ true ] True.
    #
    # @since 3.0.0
    def upsert(options = {})
      Operations.upsert(self, options).persist
    end

    module ClassMethods #:nodoc:

      # Delete all documents given the supplied conditions. If no conditions
      # are passed, the entire collection will be dropped for performance
      # benefits. Fires the destroy callbacks if conditions were passed.
      #
      # @example Destroy matching documents from the collection.
      #   Person.destroy_all(:conditions => { :title => "Sir" })
      #
      # @example Destroy all documents from the collection.
      #   Person.destroy_all
      #
      # @param [ Hash ] conditions Optional conditions to destroy by.
      #
      # @return [ Integer ] The number of documents destroyed.
      def destroy_all(conditions = nil)
        selector = conditions || {}
        documents = where(selector)
        destroyed = documents.count
        documents.each { |doc| doc.destroy }
        destroyed
      end
    end
  end
end
