# encoding: utf-8
module Mongoid #:nodoc:
  # Include this module to get soft deletion of root level documents.
  # This will add a deleted_at field to the +Document+, managed automatically.
  # Potentially incompatible with unique indices. (if collisions with deleted items)
  #
  # To use:
  #
  #   class Person
  #     include Mongoid::Document
  #     include Mongoid::Paranoia
  #   end
  module Paranoia
    extend ActiveSupport::Concern

    included do
      field :deleted_at, :type => Time
    end

    # Delete the paranoid +Document+ from the database completely. This will
    # run the destroy callbacks.
    #
    # Example:
    #
    # <tt>document.destroy!</tt>
    def destroy!
      run_callbacks(:destroy) { delete! }
    end

    # Delete the paranoid +Document+ from the database completely.
    #
    # Example:
    #
    # <tt>document.delete!</tt>
    def delete!
      @destroyed = true
      Mongoid::Persistence::Remove.new(self).persist
    end

    # Delete the +Document+, will set the deleted_at timestamp and not actually
    # delete it.
    #
    # Example:
    #
    # <tt>document._remove</tt>
    #
    # Returns:
    #
    # true
    def _remove(options = {})
      now = Time.now
      collection.update({ :_id => self.id }, { '$set' => { :deleted_at => Time.now } })
      @attributes["deleted_at"] = now
      true
    end

    alias :delete :_remove

    # Determines if this document is destroyed.
    #
    # Returns:
    #
    # true if the +Document+ was destroyed.
    def destroyed?
      @destroyed || !!deleted_at
    end

    # Restores a previously soft-deleted document. Handles this by removing the
    # deleted_at flag.
    #
    # Example:
    #
    # <tt>document.restore</tt>
    def restore
      collection.update({ :_id => self.id }, { '$unset' => { :deleted_at => true } })
      @attributes.delete("deleted_at")
    end

    module ClassMethods #:nodoc:

      # Override the default +Criteria+ accessor to only get existing
      # documents.
      #
      # Returns:
      #
      # A +Criteria+ for deleted_at not existing.
      def criteria
        super.where(:deleted_at.exists => false)
      end
      
      # Find deleted documents
      #
      # Examples:
      #
      #   <tt>Person.deleted</tt>  # all deleted employees
      #   <tt>Company.first.employees.deleted</tt>  # works with a join
      #   <tt>Person.deleted.find("4c188dea7b17235a2a000001").first</tt>  # retrieve by id a deleted person
      def deleted
        where(:deleted_at.exists => true)
      end
      
    end
  end
end
