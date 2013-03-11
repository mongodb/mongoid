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

    # Save the document - will perform an insert if the document is new, and
    # update if not.
    #
    # @example Save the document.
    #   document.save
    #
    # @param [ Hash ] options Options to pass to the save.
    #
    # @return [ true, false ] True is success, false if not.
    #
    # @since 1.0.0
    def save(options = {})
      if new_record?
        !insert(options).new_record?
      else
        update(options)
      end
    end

    # Save the document - will perform an insert if the document is new, and
    # update if not. If a validation error occurs an error will get raised.
    #
    # @example Save the document.
    #   document.save!
    #
    # @param [ Hash ] options Options to pass to the save.
    #
    # @return [ true, false ] True if validation passed.
    def save!(options = {})
      unless save(options)
        self.class.fail_validate!(self) unless errors.empty?
        self.class.fail_callback!(self, :save!)
      end
      return true
    end

    # Touch the document, in effect updating its updated_at timestamp and
    # optionally the provided field to the current time. If any belongs_to
    # relations exist with a touch option, they will be updated as well.
    #
    # @example Update the updated_at timestamp.
    #   document.touch
    #
    # @example Update the updated_at and provided timestamps.
    #   document.touch(:audited)
    #
    # @note This will not autobuild relations if those options are set.
    #
    # @param [ Symbol ] field The name of an additional field to update.
    #
    # @return [ true/false ] false if record is new_record otherwise true.
    #
    # @since 3.0.0
    def touch(field = nil)
      return false if _root.new_record?
      current = Time.now
      field = database_field_name(field)
      write_attribute(:updated_at, current) if respond_to?("updated_at=")
      write_attribute(field, current) if field

      touches = touch_atomic_updates(field)
      unless touches.empty?
        selector = atomic_selector
        _root.collection.find(selector).update(positionally(selector, touches))
      end
      run_callbacks(:touch, :after)
      true
    end

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

    # Update a single attribute and persist the entire document.
    # This skips validation but fires the callbacks.
    #
    # @example Update the attribute.
    #   person.update_attribute(:title, "Sir")
    #
    # @param [ Symbol, String ] name The name of the attribute.
    # @param [ Object ] value The new value of the attribute.a
    #
    # @raise [ Errors::ReadonlyAttribute ] If the field cannot be changed due
    #   to being flagged as reaodnly.
    #
    # @return [ true, false ] True if save was successfull, false if not.
    #
    # @since 2.0.0.rc.6
    def update_attribute(name, value)
      normalized = name.to_s
      unless attribute_writable?(normalized)
        raise Errors::ReadonlyAttribute.new(normalized, value)
      end
      write_attribute(database_field_name(normalized), value)
      save(validate: false)
    end

    # Update the document attributes in the database.
    #
    # @example Update the document's attributes
    #   document.update_attributes(:title => "Sir")
    #
    # @param [ Hash ] attributes The attributes to update.
    #
    # @return [ true, false ] True if validation passed, false if not.
    def update_attributes(attributes = {}, options = {})
      assign_attributes(attributes, options); save
    end

    # Update the document attributes in the database and raise an error if
    # validation failed.
    #
    # @example Update the document's attributes.
    #   document.update_attributes(:title => "Sir")
    #
    # @param [ Hash ] attributes The attributes to update.
    #
    # @raise [ Errors::Validations ] If validation failed.
    #
    # @return [ true, false ] True if validation passed.
    def update_attributes!(attributes = {}, options = {})
      result = update_attributes(attributes, options)
      unless result
        self.class.fail_validate!(self) unless errors.empty?
        self.class.fail_callback!(self, :update_attributes!)
      end
      result
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

      # Create a new document. This will instantiate a new document and
      # insert it in a single call. Will always return the document
      # whether save passed or not.
      #
      # @example Create a new document.
      #   Person.create(:title => "Mr")
      #
      # @example Create multiple new documents.
      #   Person.create({ title: "Mr" }, { title: "Mrs" })
      #
      # @param [ Hash, Array ] attributes The attributes to create with, or an
      #   Array of multiple attributes for multiple documents.
      # @param [ Hash ] options A mass-assignment protection options. Supports
      #   :as and :without_protection
      #
      # @return [ Document, Array<Document> ] The newly created document(s).
      #
      # @since 1.0.0
      def create(attributes = nil, options = {}, &block)
        _creating do
          if attributes.is_a?(::Array)
            attributes.map { |attrs| create(attrs, options, &block) }
          else
            doc = new(attributes, options, &block)
            doc.save
            doc
          end
        end
      end

      # Create a new document. This will instantiate a new document and
      # insert it in a single call. Will always return the document
      # whether save passed or not, and if validation fails an error will be
      # raise.
      #
      # @example Create a new document.
      #   Person.create!(:title => "Mr")
      #
      # @example Create multiple new documents.
      #   Person.create!({ title: "Mr" }, { title: "Mrs" })
      #
      # @param [ Hash, Array ] attributes The attributes to create with, or an
      #   Array of multiple attributes for multiple documents.
      # @param [ Hash ] options A mass-assignment protection options. Supports
      #   :as and :without_protection
      #
      # @return [ Document, Array<Document> ] The newly created document(s).
      #
      # @since 1.0.0
      def create!(attributes = {}, options = {}, &block)
        _creating do
          if attributes.is_a?(::Array)
            attributes.map { |attrs| create!(attrs, options, &block) }
          else
            doc = new(attributes, options, &block)
            fail_validate!(doc) unless doc.insert.errors.empty?
            fail_callback!(doc, :create!) if doc.new_record?
            doc
          end
        end
      end

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

      # Raise an error if validation failed.
      #
      # @example Raise the validation error.
      #   Person.fail_validate!(person)
      #
      # @param [ Document ] document The document to fail.
      def fail_validate!(document)
        raise Errors::Validations.new(document)
      end

      # Raise an error if a callback failed.
      #
      # @example Raise the callback error.
      #   Person.fail_callback!(person, :create!)
      #
      # @param [ Document ] document The document to fail.
      # @param [ Symbol ] method The method being called.
      #
      # @since 2.2.0
      def fail_callback!(document, method)
        raise Errors::Callback.new(document.class, method)
      end
    end
  end
end
