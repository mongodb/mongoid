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

      # Find all Documents in several ways.
      #
      # Model.find(:first, :attribute => "value")
      # Model.find(:all, :attribute => "value")
      #
      def find(*args)
        case args[0]
          when :first then find_first(args[1])
          when :all then find_all(args[1])
        end
      end

      # Find a single Document given the passed selector, which is a Hash of attributes that
      # must match the Document in the database exactly.
      def find_first(selector = nil)
        new(collection.find_one(selector))
      end

      # Find a all Documents given the passed selector, which is a Hash of attributes that
      # must match the Document in the database exactly.
      def find_all(selector = nil)
        collection.find(selector).collect { |doc| new(doc) }
      end

    end

    # Get the XGen::Mongo::Collection associated with this Document.
    def collection
      self.class.collection
    end

    # Delete this Document from the database.
    def destroy
      collection.remove(:_id => id)
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
