module Mongoloid
  module Associations
    class AssociationFactory

      def self.create(association_type, association_name, document)
        case association_type
        when :belongs_to then BelongsToAssociation.new(document)
        when :has_many then HasManyAssociation.new(association_name, document)
        when :has_one then HasOneAssociation.new(association_name, document)
        else nil
        end
      end

    end
  end
end