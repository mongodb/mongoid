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

        def set
        end
      end
    end
  end
end
