# encoding: utf-8
module Mongoid #:nodoc:

  # This module contains the behaviour for getting the various states a
  # document can transition through.
  module State

    # Returns true if the +Document+ has not been persisted to the database,
    # false if it has. This is determined by the variable @new_record
    # and NOT if the object has an id.
    #
    # @example Is the document new?
    #   person.new_record?
    #
    # @return [ true, false ] True if new, false if not.
    def new_record?
      @new_record == true
    end
    alias :new? :new_record?

    # Sets the new_record boolean - used after document is saved.
    #
    # @example Set whether the document is new.
    #   person.new_record = true
    #
    # @param [ true, false ] saved The value to set for new_record.
    #
    # @return [ true, false ] The new_record value.
    def new_record=(saved)
      @new_record = saved
    end

    # Checks if the document has been saved to the database.
    #
    # @example Is the document persisted?
    #   person.persisted?
    #
    # @return [ true, false ] True if persisted, false if not.
    def persisted?
      !new_record?
    end

    # Returns true if the +Document+ has been succesfully destroyed, and false
    # if it hasn't. This is determined by the variable @destroyed and NOT
    # by checking the database.
    #
    # @example Is the document destroyed?
    #   person.destroyed?
    #
    # @return [ true, false ] True if destroyed, false if not.
    def destroyed?
      @destroyed == true
    end
    alias :deleted? :destroyed?

    # Sets the destroyed boolean - used after document is destroyed.
    #
    # @example Set the destroyed flag.
    #   person.destroyed = true
    #
    # @return [ true, false ] The value set for destroyed.
    def destroyed=(destroyed)
      @destroyed = destroyed && true
    end
  end
end
