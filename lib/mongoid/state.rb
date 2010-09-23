# encoding: utf-8
module Mongoid #:nodoc:
  module State #:nodoc:

    # Returns true if the +Document+ has not been persisted to the database,
    # false if it has. This is determined by the variable @new_record
    # and NOT if the object has an id.
    #
    # Example:
    #
    # <tt>person.new_record?</tt>
    #
    # Returns
    #
    # true if new, false if not.
    def new_record?
      @new_record == true
    end
    alias :new? :new_record?

    # Sets the new_record boolean - used after document is saved.
    #
    # Example:
    #
    # <tt>person.new_record = true</tt>
    #
    # Options:
    #
    # saved: The value to set for new_record
    #
    # Returns:
    #
    # The new_record value.
    def new_record=(saved)
      @new_record = saved
    end

    # Checks if the document has been saved to the database.
    #
    # Example:
    #
    # <tt>person.persisted?</tt>
    #
    # Returns:
    #
    # true if persisted, false if not.
    def persisted?
      !new_record?
    end

    # Returns true if the +Document+ has been succesfully destroyed, and false if it hasn't.
    # This is determined by the variable @destroyed and NOT by checking the database.
    #
    # Example:
    #
    # <tt>person.destroyed?</tt>
    #
    # Returns:
    #
    # true if destroyed, false if not.
    def destroyed?
      @destroyed == true
    end

    # Sets the destroyed boolean - used after document is destroyed.
    #
    # Example:
    #
    # <tt>person.destroyed = true</tt>
    #
    # Returns:
    #
    # The value set for destroyed.
    def destroyed=(destroyed)
      @destroyed = destroyed && true
    end
  end
end
