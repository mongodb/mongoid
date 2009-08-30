module Mongoloid
  class Document

    attr_reader :attributes

    class << self

      # Get the XGen::Mongo::Collection associated with this Document.
      def collection
        @collection ||= Mongoloid.database.collection(@collection_name)
      end

      # Set the name of the collection to store this object in the db
      def collection_name(name)
        @collection_name = name
      end

      # Create a new Document with the supplied attribtues, and insert it into the database.
      def create(attributes = nil)
        new(attributes).save
      end

      # Defines all the fields that are accessable on the Document
      def fields(names)
        @fields = []
        names.each do |name|
          @fields << name
          define_method(name) { read_attribute(name) }
          define_method("#{name}=") { |value| write_attribute(name, value) }
        end
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

      # Find all documents in paginated fashion given the supplied arguments.
      # If no parameters are passed just default to offset 0 and limit 20.
      def paginate(selector = nil, params = {})
        collection.find(selector, Mongoloid::Paginator.new(params).options).collect { |doc| new(doc) }
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

    # Save this Document to the database and return self.
    def save
      collection.save(@attributes); self
    end

    # Update the attributes of this Document and return true
    def update_attributes(attributes)
      @attributes = attributes; save; true
    end
    
    private

    def read_attribute(name)
      @attributes[name]
    end

    def write_attribute(name, value)
      @attributes[name] = value
    end

  end
end
