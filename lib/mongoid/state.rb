# encoding: utf-8
module Mongoid #:nodoc:
  module State #:nodoc:
    # Returns true if the +Document+ has not been persisted to the database,
    # false if it has. This is determined by the variable @new_record
    # and NOT if the object has an id.
    def new_record?
      @new_record == true
    end

    # Sets the new_record boolean - used after document is saved.
    def new_record=(saved)
      @new_record = saved
    end

    # Checks if the document has been saved to the database.
    def persisted?
      !new_record?
    end

    # Returns true if the +Document+ has been succesfully destroyed, and false if it hasn't.
    # This is determined by the variable @destroyed and NOT by checking the database.
    def destroyed?
      @destroyed == true
    end

    # Sets the destroyed boolean - used after document is destroyed.
    def destroyed=(destroyed)
      @destroyed = destroyed && true
    end
  end
end
