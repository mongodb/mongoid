module Mongoloid
  class DocumentFactory

    # Create a new Mongoloid::Document. This behavior was moved here to 
    # keep Document itself under control - the constructor didn't need all
    # the logic there.
    def self.create(attributes = {})
      document_class = attributes[:document_class] || attributes["document_class"]
      document = document_class.constantize.new(attributes)
      create_associations(document, attributes)
      document
    end

    private

    # Create all the associations for the Document give the supplied attributes.
    def self.create_associations(document, attributes)
      attributes.each_key do |key|
        nested = attributes[key]
        association = document.associations[key]
        if association
          association.instance = create(nested) if nested.is_a?(Hash)
          association.instance = nested.collect { |nested_attributes| create(nested_attributes) } if nested.is_a?(Array)
        end
      end
    end

  end
end