# encoding: utf-8
require "mongoid/persistence/command"
require "mongoid/persistence/insert"
require "mongoid/persistence/insert_embedded"
require "mongoid/persistence/update"

module Mongoid #:nodoc:
  module Persistence #:nodoc:
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
  end
end
