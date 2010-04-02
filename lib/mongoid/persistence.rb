# encoding: utf-8
require "mongoid/persistence/command"
require "mongoid/persistence/insert"
require "mongoid/persistence/insert_embedded"
require "mongoid/persistence/remove"
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
    module InstanceMethods #:nodoc:
      # Remove the +Document+ from the datbase with callbacks.
      #
      # Example:
      #
      # <tt>document._destroy</tt>
      #
      # TODO: Will get rid of other #destroy once new persistence complete.
      def _destroy
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

      alias :_delete :_remove

      # Save the document - will perform an insert if the document is new, and
      # update if not. If a validation error occurs a
      # Mongoid::Errors::Validations error will get raised.
      #
      # Example:
      #
      # <tt>document._save!</tt>
      #
      # Returns:
      #
      # +true+ if validation passed, will raise error otherwise.
      def _save!
        fail_validate!(self) unless upsert; true
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
      # <tt>document._update_attributes(:title => "Sir")</tt>
      #
      # Returns:
      #
      # +true+ if validation passed, +false+ if not.
      def _update_attributes(attributes = {})
        write_attributes(attributes); update
      end

      # Update the +Document+ attributes in the datbase.
      #
      # Example:
      #
      # <tt>document._update_attributes(:title => "Sir")</tt>
      #
      # Returns:
      #
      # +true+ if validation passed, raises an error if not
      def _update_attributes!(attributes = {})
        write_attributes(attributes)
        result = update
        fail_validate!(self) unless result
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
          insert(validate).errors.any? ? false : true
        else
          update(validate)
        end
      end

      # Save is aliased so that users familiar with active record can have some
      # semblance of a familiar API.
      #
      # Example:
      #
      # <tt>document._save</tt>
      alias :_save :upsert

      protected
      # Alternative validation params.
      def parse_validate(validate)
        if validate.is_a?(Hash) && validate.has_key?(:validate)
          validate = validate[:validate]
        end
        validate
      end

      # Raise an error if validation failed.
      def fail_validate!(document)
        raise Errors::Validations.new(document.errors.full_messages)
      end
    end

    module ClassMethods #:nodoc:

    end
  end
end
