# encoding: utf-8
require "mongoid/commands/create"
require "mongoid/commands/deletion"
require "mongoid/commands/delete"
require "mongoid/commands/delete_all"
require "mongoid/commands/destroy"
require "mongoid/commands/destroy_all"
require "mongoid/commands/save"

module Mongoid #:nodoc:

  # This module is included in the +Document+ to provide all the persistence
  # methods required on the +Document+ object and class.
  module Commands
    def self.included(base)
      base.class_eval do
        include InstanceMethods
        extend ClassMethods
      end
    end

    module InstanceMethods

      # Delete the +Document+ from the database. This method is an optimized
      # delete that does not force any callbacks.
      #
      # Example:
      #
      # <tt>document.delete</tt>
      #
      # Returns: true unless an error occurs.
      def delete
        Delete.execute(self)
      end

      # Destroy the +Document+. This will delete the document from the database
      # and run the before and after destroy callbacks.
      #
      # Example:
      #
      # <tt>document.destroy</tt>
      #
      # Returns: true unless an error occurs.
      def destroy
        Destroy.execute(self)
      end

      # Save the +Document+. If the document is new, then the before and after
      # create callbacks will get executed as well as the save callbacks.
      # Otherwise only the save callbacks will run.
      #
      # Options:
      #
      # validate: Run validations or not. Defaults to true.
      #
      # Example:
      #
      # <tt>document.save # save with validations</tt>
      # <tt>document.save(false) # save without validations</tt>
      #
      # Returns: true if validation passes, false if not.
      def save(validate = true)
        new = new_record?
        run_callbacks(:before_create) if new
        saved = Save.execute(self, validate)
        run_callbacks(:after_create) if new
        saved
      end

      # Save the +Document+, dangerously. Before and after save callbacks will
      # get run. If validation fails an error will get raised.
      #
      # Example:
      #
      # <tt>document.save!</tt>
      #
      # Returns: true if validation passes
      def save!
        return save(true) || (raise Errors::Validations.new(self.errors))
      end

      # Update the document attributes and persist the document to the
      # database. Will delegate to save with all callbacks.
      #
      # Example:
      #
      # <tt>document.update_attributes(:title => "Test")</tt>
      def update_attributes(attrs = {})
        write_attributes(attrs); save
      end

      # Update the document attributes and persist the document to the
      # database. Will delegate to save!
      #
      # Example:
      #
      # <tt>document.update_attributes!(:title => "Test")</tt>
      def update_attributes!(attrs = {})
        write_attributes(attrs); save!
      end

    end

    module ClassMethods

      # Create a new +Document+. This will instantiate a new document and save
      # it in a single call. Will always return the document whether save
      # passed or not.
      #
      # Example:
      #
      # <tt>Person.create(:title => "Mr")</tt>
      #
      # Returns: the +Document+.
      def create(attributes = {})
        Create.execute(new(attributes))
      end

      # Create a new +Document+. This will instantiate a new document and save
      # it in a single call. Will always return the document whether save
      # passed or not. Will raise an error if validation fails.
      #
      # Example:
      #
      # <tt>Person.create!(:title => "Mr")</tt>
      #
      # Returns: the +Document+.
      def create!(attributes = {})
        document = Create.execute(new(attributes))
        raise Errors::Validations.new(self.errors) unless document.errors.empty?
        return document
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
        DeleteAll.execute(self, conditions)
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
        DestroyAll.execute(self, conditions)
      end

    end

  end
end
