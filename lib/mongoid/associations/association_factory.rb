module Mongoid
  module Associations
    class AssociationFactory

      # Creates a new association, based on the type provided and 
      # passes the name and document into the newly instantiated
      # association.
      #
      # If the type is invalid a InvalidAssociationError will be thrown.
      def self.create(association_type, association_name, document)
        case association_type
          when :belongs_to then BelongsToAssociation.new(document)
          when :has_many then HasManyAssociation.new(association_name, document)
          when :has_one then HasOneAssociation.new(association_name, document)
          else raise InvalidAssociationError
        end
      end

    end
  end
end