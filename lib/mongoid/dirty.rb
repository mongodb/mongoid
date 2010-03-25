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
      @modifications.keys
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
      !@modifications.empty?
    end

    # Sets up the modifications hash. This occurs just after the document is
    # instantiated.
    #
    # Example:
    #
    # <tt>document.setup_notifications</tt>
    def setup_modifications
      @modifications ||= {}
    end

    protected
    # Audit the change of a field's value.
    def modify(name, old_value, new_value)
      @attributes[name] = new_value
      @modifications[name] = [ old_value, new_value ] if @modifications
    end
  end
end
