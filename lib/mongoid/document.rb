module Mongoid #:nodoc:
  class Document
    include ActiveSupport::Callbacks
    include Validatable
    include Commands

    AGGREGATE_REDUCE = "function(obj, prev) { prev.count++; }"
    GROUP_BY_REDUCE = "function(obj, prev) { prev.group.push(obj); }"

    attr_accessor :attributes, :parent

    define_callbacks \
      :after_create,
      :after_destroy,
      :after_save,
      :before_create,
      :before_destroy,
      :before_save

    class << self

      # Get an aggregate count for the supplied group of fields and the
      # selector that is provided.
      def aggregate(fields, params = {})
        selector = params[:conditions]
        collection.group(fields, selector, { :count => 0 }, AGGREGATE_REDUCE)
      end

      # Adds the association back to the parent document. This macro is
      # necessary to set the references from the child back to the parent
      # document. If a child does not define this association calling
      # persistence methods on the child object will cause a save to fail.
      #
      # Options:
      #
      # association_name: A +Symbol+ that matches the name of the parent class.
      #
      # Example:
      #
      #   class Person < Mongoid::Document
      #     has_many :addresses
      #   end
      #
      #   class Address < Mongoid::Document
      #     belongs_to :person
      #   end
      def belongs_to(association_name)
        @embedded = true
        add_association(:belongs_to, association_name.to_s.classify, association_name)
      end

      # Get the Mongo::Collection associated with this Document.
      def collection
        return nil if @embedded
        @collection_name = self.to_s.demodulize.tableize
        @collection ||= Mongoid.database.collection(@collection_name)
      end

      # Defines all the fields that are accessable on the Document
      # For each field that is defined, a getter and setter will be
      # added as an instance method to the Document.
      #
      # Options:
      #
      # name: The name of the field, as a +Symbol+.
      # options: A +Hash+ of options to supply to the +Field+.
      #
      # Example:
      #
      # <tt>field :score, :default => 0</tt>
      def field(name, options = {})
        @fields ||= {}
        @fields[name] = Field.new(name, options)
        define_method(name) { read_attribute(name) }
        define_method("#{name}=") { |value| write_attribute(name, value) }
      end

      # Returns all the fields for the Document as a +Hash+ with names as keys.
      def fields
        @fields
      end

      # Find a +Document+ in several different ways.
      #
      # If a +String+ is provided, it will be assumed that it is a
      # representation of a Mongo::ObjectID and will attempt to find a single
      # +Document+ based on that id. If a +Symbol+ and +Hash+ is provided then
      # it will attempt to find either a single +Document+ or multiples based
      # on the conditions provided and the first parameter.
      #
      # <tt>Person.find(:first, :conditions => { :attribute => "value" })</tt>
      #
      # <tt>Person.find(:all, :conditions => { :attribute => "value" })</tt>
      #
      # <tt>Person.find(Mongo::ObjectID.new.to_s)</tt>
      def find(*args)
        Criteria.translate(*args).execute(self)
      end

      # Find a single Document given the passed selector, which is a Hash of attributes that
      # must match the Document in the database exactly.
      def first(*args)
        find(:first, *args)
      end

      # Find all Documents given the passed selector, which is a Hash of attributes that
      # must match the Document in the database exactly.
      def all(*args)
        find(:all, *args)
      end

      # Find all Documents given the supplied criteria, grouped by the fields
      # provided.
      def group_by(fields, params = {})
        selector = params[:condition]
        collection.group(fields, selector, { :group => [] }, GROUP_BY_REDUCE).collect do |docs|
          docs["group"] = docs["group"].collect { |attrs| new(attrs) }; docs
        end
      end

      # Adds the association from a parent document to its children. The name
      # of the association needs to be a pluralized form of the child class
      # name.
      #
      # Options:
      #
      # association_name: A +Symbol+ that is the plural child class name.
      #
      # Example:
      #
      #   class Person < Mongoid::Document
      #     has_many :addresses
      #   end
      #
      #   class Address < Mongoid::Document
      #     belongs_to :person
      #   end
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
        field :created_at
        field :last_modified
        class_eval do
          before_create \
            :update_created_at,
            :update_last_modified
          before_save :update_last_modified
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
        selector = params[:conditions]
        WillPaginate::Collection.create(
          params[:page] || 1,
          params[:per_page] || 20,
          0) do |pager|
            results = collection.find(selector, { :sort => params[:sort],
                                                  :limit => pager.per_page,
                                                  :skip => pager.offset })
            pager.total_entries = results.count
            pager.replace(results.collect { |doc| new(doc) })
        end
      end

      # Entry point for creating a new criteria from a Document. This will
      # instantiate a new +Criteria+ object with the supplied select criterion
      # already added to it.
      #
      # Options:
      #
      # args: A list of field names to retrict the returned fields to.
      #
      # Example:
      #
      # <tt>Person.select(:field1, :field2, :field3)</tt>
      #
      # Returns: <tt>Criteria</tt>
      def select(*args)
        Criteria.new(:all).select(*args)
      end

    end

    # Get the Mongo::Collection associated with this Document.
    def collection
      self.class.collection
    end

    # Get the fields for the Document class.
    def fields
      self.class.fields
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

    # Returns the id of the Document
    def to_param
      id.to_s
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
          object.parentize(self)
          @attributes[name] = object.mongoidize
        end
      end

    end

    # Read from the attributes hash.
    def read_attribute(name)
      symbol = name.to_sym
      fields[symbol].value(@attributes[symbol])
    end

    # Update the created_at field on the Document to the current time. This is
    # only called on create.
    def update_created_at
      self.created_at = Time.now
    end

    # Update the last_modified field on the Document to the current time.
    # This is only called on create and on save.
    def update_last_modified
      self.last_modified = Time.now
    end

    # Write to the attributes hash.
    def write_attribute(name, value)
      symbol = name.to_sym
      @attributes[name.to_sym] = fields[symbol].value(value)
    end

  end
end
