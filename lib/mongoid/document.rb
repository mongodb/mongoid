module Mongoid #:nodoc:
  class Document #:nodoc:
    include ActiveSupport::Callbacks
    include Validatable

    AGGREGATE_REDUCE = "function(obj, prev) { prev.count++; }"
    GROUP_BY_REDUCE = "function(obj, prev) { prev.group.push(obj); }"

    attr_reader :attributes, :parent

    define_callbacks \
      :after_create,
      :after_save,
      :before_create,
      :before_save

    class << self

      # Create an association to a parent Document.
      # Get an aggregate count for the supplied group of fields and the
      # selector that is provided.
      def aggregate(fields, selector)
        collection.group(fields, selector, { :count => 0 }, AGGREGATE_REDUCE)
      end

      def belongs_to(association_name)
        add_association(:belongs_to, association_name.to_s.classify, association_name)
      end

      # Get the Mongo::Collection associated with this Document.
      def collection
        @collection_name = self.to_s.demodulize.tableize
        @collection ||= Mongoid.database.collection(@collection_name)
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

      # Find all Documents in several ways.
      # Model.find(:first, :attribute => "value")
      # Model.find(:all, :attribute => "value")
      def find(*args)
        type, selector = args[0], args[1]
        conditions = selector[:conditions] if selector
        case type
        when :all then find_all(conditions)
        when :first then find_first(conditions)
        else find_first(Mongo::ObjectID.from_string(type.to_s))
        end
      end

      # Find a single Document given the passed selector, which is a Hash of attributes that
      # must match the Document in the database exactly.
      def find_first(selector = nil)
        new(collection.find_one(selector))
      end

      # Find all Documents given the passed selector, which is a Hash of attributes that
      # must match the Document in the database exactly.
      def find_all(selector = nil)
        collection.find(selector).collect { |doc| new(doc) }
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

      # Find all Documents given the supplied criteria, grouped by the fields
      # provided.
      def group_by(fields, selector)
        collection.group(fields, selector, { :group => [] }, GROUP_BY_REDUCE).collect do |docs|
          docs["group"] = docs["group"].collect { |attrs| new(attrs) }; docs
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
        fields :created_on, :last_modified
        class_eval do
          before_save :update_timestamps
        end
      end

      # Adds an index on the field specified. Options can be :unique => true or
      # :unique => false. It will default to the latter.
      def index(name, options = { :unique => false })
        collection.create_index(name, options)
      end

      # Find all documents in paginated fashion given the supplied arguments.
      # If no parameters are passed just default to offset 0 and limit 20.
      def paginate(params = {})
        WillPaginate::Collection.create(
          params[:page] || 1,
          params[:per_page] || 20,
          0) do |pager|
            results = collection.find(params[:conditions], { :limit => pager.per_page, :offset => pager.offset })
            pager.total_entries = results.count
            pager.replace(results.collect { |doc| new(doc) })
        end
      end

    end

    # Get the Mongo::Collection associated with this Document.
    def collection
      self.class.collection
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

    def update_timestamps
      self.created_on = Time.now
      self.last_modified = Time.now
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

    # Write to the attributes hash.
    def write_attribute(name, value)
      @attributes[name.to_sym] = value
    end

  end
end
