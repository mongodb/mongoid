# encoding: utf-8
require "mongoid/persistence/atomic"
require "mongoid/persistence/deletion"
require "mongoid/persistence/insertion"
require "mongoid/persistence/modification"
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

    # Remove the document from the database with callbacks.
    #
    # @example Destroy a document.
    #   document.destroy
    #
    # @param [ Hash ] options Options to pass to destroy.
    #
    # @return [ true, false ] True if successful, false if not.
    def destroy(options = {})
      self.flagged_for_destroy = true
      result = run_callbacks(:destroy) do
        remove(options)
      end
      self.flagged_for_destroy = false
      result
    end

    # Insert a new document into the database. Will return the document
    # itself whether or not the save was successful.
    #
    # @example Insert a document.
    #   document.insert
    #
    # @param [ Hash ] options Options to pass to insert.
    #
    # @return [ Document ] The persisted document.
    def insert(options = {})
      Operations.insert(self, options).persist
    end

    # Remove the document from the database.
    #
    # @example Remove the document.
    #   document.remove
    #
    # @param [ Hash ] options Options to pass to remove.
    #
    # @return [ TrueClass ] True.
    def remove(options = {})
      Operations.remove(self, options).persist
    end
    alias :delete :remove

    # Update the document in the database.
    #
    # @example Update an existing document.
    #   document.update
    #
    # @param [ Hash ] options Options to pass to update.
    #
    # @return [ true, false ] True if succeeded, false if not.
    def update(options = {})
      Operations.update(self, options).persist
    end

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
      # benefits. Does not fire any callbacks.
      #
      # @example Delete matching documents from the collection.
      #   Person.delete_all(:conditions => { :title => "Sir" })
      #
      # @example Delete all documents from the collection.
      #   Person.delete_all
      #
      # @param [ Hash ] conditions Optional conditions to delete by.
      #
      # @return [ Integer ] The number of documents deleted.
      def delete_all(conditions = nil)
        conds = conditions || {}
        selector = conds[:conditions] || conds
        selector.merge!(_type: name) if hereditary?
        coll = collection
        deleted = coll.find(selector).count
        coll.find(selector).remove_all
        Threaded.clear_options!
        deleted
      end

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
        conds = conditions || {}
        documents = where(conds[:conditions] || conds)
        destroyed = documents.count
        documents.each { |doc| doc.destroy }
        destroyed
      end
    end
  end
end
