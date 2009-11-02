module Mongoid #:nodoc:
  module Associations #:nodoc:
    class Accessor #:nodoc:
      class << self
        # Gets an association, based on the type provided and
        # passes the name and document into the newly instantiated
        # association.
        #
        # If the type is invalid a InvalidAssociationError will be thrown.
        def get(type, name, document, options = {})
          case type
            when :belongs_to then BelongsTo.new(document)
            when :has_many then HasMany.new(name, document, options)
            when :has_one then HasOne.new(name, document, options)
            else raise InvalidAssociationError
          end
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
          case type
            when :belongs_to then BelongsTo.update(document, object)
            when :has_many then HasMany.update(object, document, name)
            when :has_one then HasOne.update(object, document, name)
            else raise InvalidAssociationError
          end
        end
      end
    end
  end
end
