module Mongoid #:nodoc:
  module Associations #:nodoc:
    class Accessor #:nodoc:
      class << self
        # Gets an association, based on the type provided and
        # passes the name and document into the newly instantiated
        # association.
        def get(type, name, document, options = {})
          document ? type.new(name, document, options) : nil
        end

        # Set an object association. This is used to set the parent reference
        # in a +BelongsTo+, a child reference in a +HasOne+, or many child
        # references in a +HasMany+.
        #
        # Options:
        #
        # type: The association type
        # name: The name of the association
        # document: The base document to handle the access for.
        # object: The object that was passed in to the setter method.
        # options: optional options.
        def set(type, name, document, object, options ={})
          type.update(object, document, name)
        end
      end
    end
  end
end
