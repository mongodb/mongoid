# encoding: utf-8
require "mongoid/commands/create"
require "mongoid/commands/delete"
require "mongoid/commands/delete_all"
require "mongoid/commands/destroy"
require "mongoid/commands/destroy_all"
require "mongoid/commands/save"

module Mongoid #:nodoc:

  # This module is included in the +Document+ to provide all the persistence
  # methods required on the +Document+ object and class. The following methods
  # are provided:
  #
  # <tt>create</tt>,
  # <tt>create!</tt>,
  # <tt>delete</tt>,
  # <tt>delete_all</tt>,
  # <tt>destroy</tt>,
  # <tt>destroy_all</tt>,
  # <tt>save</tt>,
  # <tt>save!</tt>,
  # <tt>update_attributes</tt>,
  # <tt>update_attributes!</tt>
  #
  # These methods will delegate to their respective commands.
  module Commands
    def self.included(base)
      base.class_eval do
        include InstanceMethods
        extend ClassMethods
      end
    end

    module InstanceMethods

      # Delete the +Document+ from the database. Delegates to the Delete
      # command.
      def delete
        Delete.execute(self)
      end

      # Destroy the +Document+. Delegates to the Destroy command.
      def destroy
        Destroy.execute(self)
      end

      # Save the +Document+. Delegates to the Save command.
      def save
        new_record? ? Create.execute(self) : Save.execute(self)
      end

      # Save the +Document+. Delegates to the Save command. If the command
      # returns false then a +ValidationError+ will be raised.
      def save!
        if new_record?
          return Create.execute(self) || (raise Errors::Validations.new(self.errors))
        else
          return Save.execute(self) || (raise Errors::Validations.new(self.errors))
        end
      end

      # Update the attributes of the +Document+. Will call save after the
      # attributes have been updated.
      def update_attributes(attrs = {})
        write_attributes(attrs); save
      end

      # Update the attributes of the +Document+. Will call save! after the
      # attributes have been updated, causing a +ValidationError+ if the
      # +Document+ failed validation.
      def update_attributes!(attrs = {})
        write_attributes(attrs); save!
      end

    end

    module ClassMethods

      # Create a new +Document+ with the supplied attributes. Will delegate to
      # the Create command.
      def create(attributes = {})
        Create.execute(new(attributes))
      end

      # Create a new +Document+ with the supplied attributes. Will delegate to
      # the Create command or raise +ValidationError+ if the save failed
      # validation.
      def create!(attributes = {})
        document = Create.execute(new(attributes))
        raise Errors::Validations.new(self.errors) unless document.errors.empty?
        return document
      end

      # Delete all the +Documents+ in the database given the supplied
      # conditions.
      def delete_all(conditions = {})
        DeleteAll.execute(self, conditions)
      end

      # Destroy all the +Documents+ in the database given the supplied
      # conditions.
      def destroy_all(conditions = {})
        DestroyAll.execute(self, conditions)
      end

    end

  end
end
