# encoding: utf-8
module Mongoid

  # Include this module to get soft deletion of root level documents.
  # This will add a deleted_at field to the +Document+, managed automatically.
  # Potentially incompatible with unique indices. (if collisions with deleted items)
  #
  # @example Make a document paranoid.
  #   class Person
  #     include Mongoid::Document
  #     include Mongoid::Paranoia
  #   end
  module Paranoia
    extend ActiveSupport::Concern

    included do
      field :deleted_at, type: Time
      self.paranoid = true

      default_scope where(deleted_at: nil)
      scope :deleted, ne(deleted_at: nil)
    end

    # Delete the paranoid +Document+ from the database completely. This will
    # run the destroy callbacks.
    #
    # @example Hard destroy the document.
    #   document.destroy!
    #
    # @return [ true, false ] If the operation succeeded.
    #
    # @since 1.0.0
    def destroy!
      run_callbacks(:destroy) { delete! }
    end

    # Delete the paranoid +Document+ from the database completely.
    #
    # @example Hard delete the document.
    #   document.delete!
    #
    # @return [ true, false ] If the operation succeeded.
    #
    # @since 1.0.0
    def delete!
      Persistence::Operations.remove(self).persist
    end

    # Delete the +Document+, will set the deleted_at timestamp and not actually
    # delete it.
    #
    # @example Soft remove the document.
    #   document.remove
    #
    # @param [ Hash ] options The database options.
    #
    # @return [ true ] True.
    #
    # @since 1.0.0
    def remove(options = {})
      cascade!
      time = self.deleted_at = Time.now
      paranoid_collection.find(atomic_selector).
        update({ "$set" => { paranoid_field => time }})
      @destroyed = true
      IdentityMap.remove(self)
      Threaded.clear_options!
      true
    end
    alias :delete :remove

    # Determines if this document is destroyed.
    #
    # @example Is the document destroyed?
    #   person.destroyed?
    #
    # @return [ true, false ] If the document is destroyed.
    #
    # @since 1.0.0
    def destroyed?
      (@destroyed ||= false) || !!deleted_at
    end
    alias :deleted? :destroyed?

    # Restores a previously soft-deleted document. Handles this by removing the
    # deleted_at flag.
    #
    # @example Restore the document from deleted state.
    #   document.restore
    #
    # @return [ Time ] The time the document had been deleted.
    #
    # @since 1.0.0
    def restore
      paranoid_collection.find(atomic_selector).
        update({ "$unset" => { paranoid_field => true }})
      attributes.delete("deleted_at")
      @destroyed = false
      true
    end

    # Returns a string representing the documents's key suitable for use in URLs.
    def to_param
      new_record? ? nil : to_key.join('-')
    end

    private

    # Get the collection to be used for paranoid operations.
    #
    # @example Get the paranoid collection.
    #   document.paranoid_collection
    #
    # @return [ Collection ] The root collection.
    #
    # @since 2.3.1
    def paranoid_collection
      embedded? ? _root.collection : self.collection
    end

    # Get the field to be used for paranoid operations.
    #
    # @example Get the paranoid field.
    #   document.paranoid_field
    #
    # @return [ String ] The deleted at field.
    #
    # @since 2.3.1
    def paranoid_field
      embedded? ? "#{atomic_position}.deleted_at" : "deleted_at"
    end
  end
end
