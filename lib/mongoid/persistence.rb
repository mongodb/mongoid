# encoding: utf-8
require "mongoid/persistence/command"
require "mongoid/persistence/insert"
require "mongoid/persistence/insert_embedded"
require "mongoid/persistence/remove"
require "mongoid/persistence/remove_all"
require "mongoid/persistence/remove_embedded"
require "mongoid/persistence/update"

module Mongoid #:nodoc:
  # The persistence module is a mixin to provide database accessor methods for
  # the document. These correspond to the appropriate accessors on a
  # +Mongo::Collection+ and retain the same DSL.
  #
  # Examples:
  #
  # <tt>document.insert</tt>
  # <tt>document.update</tt>
  # <tt>document.upsert</tt>
  module Persistence
    extend ActiveSupport::Concern
    # Remove the +Document+ from the datbase with callbacks.
    #
    # Example:
    #
    # <tt>document.destroy</tt>
    #
    # TODO: Will get rid of other #destroy once new persistence complete.
    def destroy
      run_callbacks(:destroy) { self.destroyed = true if _remove }
    end

    # Insert a new +Document+ into the database. Will return the document
    # itself whether or not the save was successful.
    #
    # Example:
    #
    # <tt>document.insert</tt>
    def insert(validate = true)
      Insert.new(self, validate).persist
    end

    # Remove the +Document+ from the datbase.
    #
    # Example:
    #
    # <tt>document._remove</tt>
    #
    # TODO: Will get rid of other #remove once observable pattern killed.
    def _remove
      Remove.new(self).persist
    end

    alias :delete :_remove

    # Save the document - will perform an insert if the document is new, and
    # update if not. If a validation error occurs a
    # Mongoid::Errors::Validations error will get raised.
    #
    # Example:
    #
    # <tt>document.save!</tt>
    #
    # Returns:
    #
    # +true+ if validation passed, will raise error otherwise.
    def save!
      self.class.fail_validate!(self) unless upsert; true
    end

    # Update the +Document+ in the datbase.
    #
    # Example:
    #
    # <tt>document.update</tt>
    def update(validate = true)
      Update.new(self, validate).persist
    end

    # Update the +Document+ attributes in the datbase.
    #
    # Example:
    #
    # <tt>document.update_attributes(:title => "Sir")</tt>
    #
    # Returns:
    #
    # +true+ if validation passed, +false+ if not.
    def update_attributes(attributes = {})
      write_attributes(attributes); update
    end

    # Update the +Document+ attributes in the datbase.
    #
    # Example:
    #
    # <tt>document.update_attributes(:title => "Sir")</tt>
    #
    # Returns:
    #
    # +true+ if validation passed, raises an error if not
    def update_attributes!(attributes = {})
      write_attributes(attributes)
      result = update
      self.class.fail_validate!(self) unless result
      result
    end

    # Upsert the document - will perform an insert if the document is new, and
    # update if not.
    #
    # Example:
    #
    # <tt>document.upsert</tt>
    #
    # Returns:
    #
    # A +Boolean+ for updates.
    def upsert(validate = true)
      validate = parse_validate(validate)
      if new_record?
        insert(validate).persisted?
      else
        update(validate)
      end
    end

    # Save is aliased so that users familiar with active record can have some
    # semblance of a familiar API.
    #
    # Example:
    #
    # <tt>document.save</tt>
    alias :save :upsert

    protected
    # Alternative validation params.
    def parse_validate(validate)
      if validate.is_a?(Hash) && validate.has_key?(:validate)
        validate = validate[:validate]
      end
      validate
    end

    module ClassMethods #:nodoc:

      # Create a new +Document+. This will instantiate a new document and
      # insert it in a single call. Will always return the document
      # whether save passed or not.
      #
      # Example:
      #
      # <tt>Person.create(:title => "Mr")</tt>
      #
      # Returns: the +Document+.
      def create(attributes = {})
        new(attributes).tap(&:insert)
      end

      # Create a new +Document+. This will instantiate a new document and
      # insert it in a single call. Will always return the document
      # whether save passed or not, and if validation fails an error will be
      # raise.
      #
      # Example:
      #
      # <tt>Person.create!(:title => "Mr")</tt>
      #
      # Returns: the +Document+.
      def create!(attributes = {})
        document = new(attributes)
        fail_validate!(document) if document.insert.errors.any?
        document
      end

      # Delete all documents given the supplied conditions. If no conditions
      # are passed, the entire collection will be dropped for performance
      # benefits. Does not fire any callbacks.
      #
      # Example:
      #
      # <tt>Person.delete_all(:conditions => { :title => "Sir" })</tt>
      # <tt>Person.delete_all</tt>
      #
      # Returns: true or raises an error.
      def delete_all(conditions = {})
        RemoveAll.new(
          self,
          false,
          conditions[:conditions] || {}
        ).persist
      end

      # Delete all documents given the supplied conditions. If no conditions
      # are passed, the entire collection will be dropped for performance
      # benefits. Fires the destroy callbacks if conditions were passed.
      #
      # Example:
      #
      # <tt>Person.destroy_all(:conditions => { :title => "Sir" })</tt>
      # <tt>Person.destroy_all</tt>
      #
      # Returns: true or raises an error.
      def destroy_all(conditions = {})
        documents = all(conditions)
        count = documents.count
        documents.each { |doc| doc.destroy }; count
      end

      # Raise an error if validation failed.
      def fail_validate!(document)
        raise Errors::Validations.new(document.errors)
      end
    end
  end
end
