module Mongoloid
  class DocumentFactory

    # Create a new Mongoloid::Document. This behavior was moved here to 
    # keep Document itself under control - the constructor didn't need all
    # the logic there.
    def self.create(attributes = {})
      document_class = attributes[:document_class] || attributes["document_class"]
      document = document_class.constantize.new(attributes)
      Mongoloid::AssociationFactory.create(document, attributes)
      document
    end

  end
end