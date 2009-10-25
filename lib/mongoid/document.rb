module Mongoid #:nodoc:
  class Document
    include ActiveSupport::Callbacks
    include Commands, Observable, Validatable
    extend Associations

    attr_accessor :parent
    attr_reader :attributes

    define_callbacks \
      :after_create,
      :after_destroy,
      :after_save,
      :before_create,
      :before_destroy,
      :before_save

    class << self

      # Find +Documents+ given the conditions.
      #
      # Options:
      #
      # args: A +Hash+ with a conditions key and other options
      #
      # <tt>Person.all(:conditions => { :attribute => "value" })</tt>
      def all(*args)
        find(:all, *args)
      end

      # Returns the collection associated with this +Document+. If the
      # document is embedded, there will be no collection associated
      # with it.
      #
      # Returns: <tt>Mongo::Collection</tt>
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

      # Find the first +Document+ given the conditions.
      #
      # Options:
      #
      # args: A +Hash+ with a conditions key and other options
      #
      # <tt>Person.first(:conditions => { :attribute => "value" })</tt>
      def first(*args)
        find(:first, *args)
      end

      # Adds an index on the field specified. Options can be :unique => true or
      # :unique => false. It will default to the latter.
      def index(name, options = { :unique => false })
        collection.create_index(name, options)
      end

      # Defines the field that will be used for the id of this +Document+. This
      # set the id of this +Document+ before save to a parameterized version of
      # the field that was supplied. This is good for use for readable URLS in
      # web applications and *MUST* be defined on documents that are embedded
      # in order for proper updates in has_may associations.
      def key(field)
        @primary_key = field
        before_save :generate_key
      end

      # Returns the primary key field of the +Document+
      def primary_key
        @primary_key
      end

      # Find all documents in paginated fashion given the supplied arguments.
      # If no parameters are passed just default to offset 0 and limit 20.
      #
      # Options:
      #
      # params: A +Hash+ of params to pass to the Criteria API.
      #
      # Example:
      #
      # <tt>Person.paginate(:conditions => { :field => "Test" }, :page => 1,
      # :per_page => 20)</tt>
      #
      # Returns paginated array of docs.
      def paginate(params = {})
        criteria = Criteria.translate(:all, params)
        WillPaginate::Collection.create(criteria.page, criteria.offset, 0) do |pager|
          results = criteria.execute(self)
          pager.total_entries = results.size
          pager.replace(results)
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
        Criteria.new(:all, self).select(*args)
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

    # Return the +Document+ primary key.
    def primary_key
      self.class.primary_key
    end

    # Returns true is the Document has not been persisted to the database, false if it has.
    def new_record?
      @attributes[:_id].nil?
    end

    # Notify observers that this Document has changed.
    def notify
      changed(true)
      notify_observers(self)
    end

    # Read from the attributes hash.
    def read_attribute(name)
      symbol = name.to_sym
      fields[symbol].value(@attributes[symbol])
    end

    # Returns the id of the Document
    def to_param
      id.to_s
    end

    # Update the document based on notify from child
    def update(child)
      name = child.class.to_s.downcase.demodulize.to_sym
      write_attribute(name, child.attributes)
    end

    # Write to the attributes hash.
    def write_attribute(name, value)
      symbol = name.to_sym
      @attributes[name.to_sym] = value
      notify
    end

    # Writes all the attributes of this Document, and delegate up to 
    # the parent.
    def write_attributes(attrs)
      @attributes = attrs
      notify
    end

    private
    def generate_key
      @attributes[:_id] = @attributes[primary_key].parameterize.to_s
    end
  end
end
