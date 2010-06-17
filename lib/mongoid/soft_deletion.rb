# encoding: utf-8
require "mongoid/persistence/remove"
module Mongoid
  # Include this module to get soft deletion of root level documents.
  # This will add a deleted_at field to the +Document+, managed automatically.
  # Potentially incompatible with unique indices. (if collisions with deleted items)
  module SoftDeleteAddition
    # Find deleted documents
    #
    # Examples:
    #
    #   <tt>Person.deleted</tt>  # all deleted employees
    #   <tt>Company.first.employees.deleted</tt>  # works with a join
    #   <tt>Person.deleted.find("4c188dea7b17235a2a000001").first</tt>  # retrieve by id a deleted person
    def deleted
      where(:deleted_at.ne => nil)
    end
  end

  module SoftDeletion
    extend ActiveSupport::Concern

    included do
      Mongoid::Criteria.send(:include, Mongoid::SoftDeleteAddition)
      field :deleted_at, :type => Time
    end

    # Hard-delete a document.
    def hard_destroy
      Mongoid::Persistence::Remove.new(self).persist
    end

    # Soft-delete a document.
    def _remove
      collection.update({:_id => self.id}, { '$set' => {:deleted_at => (now = Time.now)} }) && true
    end
    alias :delete :_remove

    # Determines if this document is destroyed.
    def destroyed
      !!deleted_at
    end

    # Restores a previously soft-deleted document.
    def restore
      collection.update({:_id => self.id}, { '$set' => {:deleted_at => nil} })
    end

    module ClassMethods
      def criteria
        super.where(:deleted_at => nil)
      end
    end
  end
end
