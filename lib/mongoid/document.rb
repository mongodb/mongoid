module Mongoid #:nodoc:
  class Document #:nodoc:
    include Finders
    include ActiveSupport::Callbacks
    include Validatable

    attr_reader :attributes, :parent

    define_callbacks \
      :after_create,
      :after_save,
      :before_create,
      :before_save

    class << self

      def belongs_to(association_name)
        add_association(:belongs_to, association_name.to_s.classify, association_name)
      end

      # Create a new Document with the supplied attribtues, and insert it into the database.
      def create(attributes = {})
        new(attributes).save(true)
      end

      # Deletes all records from the collection. Will actually call drop on the
      # Mongo::Collection for efficiency.
      def destroy_all
        collection.drop
      end

      # Defines all the fields that are accessable on the Document
      # For each field that is defined, a getter and setter will be
      # added as an instance method to the Document.
      def fields(*names)
        @fields ||= []
        names.flatten.each do |name|
          @fields << name
          define_method(name) { read_attribute(name) }
          define_method("#{name}=") { |value| write_attribute(name, value) }
        end
      end

      # Create a one-to-many association between Documents.
      def has_many(association_name)
        add_association(:has_many, association_name.to_s.classify, association_name)
      end

      # Create a one-to-many association between Documents.
      def has_one(association_name)
        add_association(:has_one, association_name.to_s.titleize, association_name)
      end

      # Adds timestamps on the Document in the form of the fields 'created_on'
      # and 'last_modified'
      def has_timestamps
        fields :created_at, :last_modified
        class_eval do
          before_save :update_timestamps
        end
      end

      # Adds an index on the field specified. Options can be :unique => true or
      # :unique => false. It will default to the latter.
      def index(name, options = { :unique => false })
        collection.create_index(name, options)
      end

    end

    # Delete this Document from the database.
    def destroy
      collection.remove(:_id => id)
    end

    # Get the Mongo::ObjectID associated with this object.
    # This is in essence the primary key.
    def id
      @attributes[:_id]
    end

    # Instantiate a new Document, setting the Document's attirbutes if given.
    # If no attributes are provided, they will be initialized with an empty Hash.
    def initialize(attributes = {})
      @attributes = attributes.symbolize_keys if attributes
      @attributes = {} unless attributes
    end

    # Returns true is the Document has not been persisted to the database, false if it has.
    def new_record?
      @attributes[:_id].nil?
    end

    # Set the parent to this document.
    def parent=(document)
      @parent = document
    end

    # Save this document to the database. If this document is the root document
    # in the object graph, it will save itself, and return self. If the
    # document is embedded within another document, or is multiple levels down
    # the tree, the root object will get saved, and return itself.
    def save(creating = false)
      if @parent
        @parent.save
      else
        run_callbacks(:before_create) if creating
        run_callbacks(:before_save)
        collection.save(@attributes)
        run_callbacks(:after_create) if creating
        run_callbacks(:after_save)
        return self
      end
    end

    # Returns the id of the Document
    def to_param
      id.to_s
    end

    # Update the attributes of this Document and return true
    def update_attributes(attributes)
      @attributes = attributes.symbolize_keys!; save; true
    end

    private

    class << self

      # Adds the association to the associations hash with the type as the key,
      # then adds the accessors for the association.
      def add_association(type, class_name, name)
        define_method(name) do
          Mongoid::Associations::Factory.create(type, name, self)
        end
        define_method("#{name}=") do |object|
          @attributes[name] = object.mongoidize
        end
      end

    end

    # Read from the attributes hash.
    def read_attribute(name)
      @attributes[name.to_sym]
    end

    # Update the timestamps on this document.
    def update_timestamps
      self.created_at = Time.now
      self.last_modified = Time.now
    end

    # Write to the attributes hash.
    def write_attribute(name, value)
      @attributes[name.to_sym] = value
    end

  end
end
