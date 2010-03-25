# encoding: utf-8
module Mongoid #:nodoc:
  module Dirty #:nodoc:
    # Gets the names of all the fields that have changed in the document.
    #
    # Example:
    #
    #   person = Person.new(:title => "Sir")
    #   person.title = "Madam"
    #   person.changed # returns [ "title" ]
    #
    # Returns:
    #
    # An +Array+ of changed field names.
    def changed
      @modified_attributes
    end

    # Alerts to whether the document has been modified or not.
    #
    # Example:
    #
    #   person = Person.new(:title => "Sir")
    #   person.title = "Madam"
    #   person.changed? # returns true
    #
    # Returns:
    #
    # +true+ if changed, +false+ if not.
    def changed?
      !@modified_attributes.empty?
    end
  end
end
