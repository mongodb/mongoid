module Mongoloid
  class Document

    attr_reader :attributes

    class << self

      # Get the XGen::Mongo::Collection associated with this Document.
      def collection
        @collection ||= Mongoloid.database.collection(self.class.to_s.downcase)
      end

      # Create a new Document with the supplied attribtues, and insert it into the database.
      def create(attributes = nil)
        new(attributes).save
      end
      
      # Find all Documents for the given selector, or return all Documents if selector is nil.
      def find(selector = nil)
        collection.find(selector).collect { |doc| new(doc) }
      end

    end

    # Get the XGen::Mongo::Collection associated with this Document.
    def collection
      self.class.collection
    end

    # Get the XGen::Mongo::ObjectID associated with this object.
    # This is in essence the primary key.
    def id
      @attributes[:_id]
    end

    # Instantiate a new Document, setting the Document's attirbutes if given.
    # If no attributes are provided, they will be initialized with an empty Hash.
    def initialize(attributes = nil)
      @attributes = attributes || {}
    end

    # Returns true is the Document has not been persisted to the database, false if it has.
    def new_record?
      @attributes[:_id].nil?
    end

    # Save this Document to the database, and return self.
    def save
      collection.save(@attributes)
      self
    end

  end
end
