# encoding: utf-8
require "mongoid/persistence/command"
require "mongoid/persistence/insert"
require "mongoid/persistence/insert_embedded"
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
    # Insert a new +Document+ into the database. Will return the document
    # itself whether or not the save was successful.
    #
    # Example:
    #
    # <tt>document.insert</tt>
    def insert
      Insert.new(self).persist
    end

    # Update the +Document+ in the datbase.
    #
    # Example:
    #
    # <tt>document.update</tt>
    def update
      Update.new(self).persist
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
    # A +Boolean+ for updates, the +Document+ for inserts.
    def upsert
      new_record? ? insert : update
    end
  end
end
