module Mongoloid
  class AssociationFactory

    # Create a new Association given the provided parent Document 
    # and the provided attributes. This will callback to the DocumentFactory
    # to instantiate and new objects.
    def self.create(document, attributes = {})
      attributes.each do |key, value|
        association = document.associations[key]
        if association
          case value
          when Hash then association.instance = Mongoloid::DocumentFactory.create(value)
          when Array then association.instance = value.collect { |nested| Mongoloid::DocumentFactory.create(nested) }
          else raise TypeMismatchError
          end
        end
      end
    end

  end
end
