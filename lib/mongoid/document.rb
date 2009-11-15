module Mongoid #:nodoc:
  class Document
    include ActiveSupport::Callbacks
    include Associations, Attributes, Commands, Observable, Validatable

    attr_accessor :association_name, :parent
    attr_reader :attributes, :new_record

    define_callbacks \
      :after_create,
      :after_destroy,
      :after_save,
      :after_update,
      :after_validation,
      :before_create,
      :before_destroy,
      :before_save,
      :before_update,
      :before_validation

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
        return nil if embedded?
        @collection_name = self.to_s.demodulize.tableize
        @collection ||= Mongoid.database.collection(@collection_name)
      end

      # Returns a count of matching records in the database based on the
      # provided arguments.
      #
      # <tt>Person.count(:first, :conditions => { :attribute => "value" })</tt>
      def count(*args)
        Criteria.translate(*args).count(self)
      end

      # Returns a hash of all the default values
      def defaults
        @defaults
      end

      # return true if the +Document+ is embedded in another +Documnet+.
      def embedded?
        @embedded == true
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
        @fields ||= {}.with_indifferent_access
        @defaults ||= {}.with_indifferent_access
        @fields[name.to_s] = Field.new(name.to_s, options)
        @defaults[name.to_s] = options[:default] if options[:default]
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

      # Find a +Document+ by its id.
      def find_by_id(id)
        find(id)
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

      # Instantiate a new object, only when loaded from the database.
      def instantiate(attrs = {})
        attributes = attrs.with_indifferent_access
        if attributes[:_id]
          document = allocate
          document.instance_variable_set(:@attributes, attributes)
          return document
        else
          return new(attributes)
        end
      end

      # Defines the field that will be used for the id of this +Document+. This
      # set the id of this +Document+ before save to a parameterized version of
      # the field that was supplied. This is good for use for readable URLS in
      # web applications and *MUST* be defined on documents that are embedded
      # in order for proper updates in has_may associations.
      def key(*fields)
        @primary_key = fields
        before_save :generate_key
      end

      # Find the last +Document+ in the collection by reverse id
      def last
        find(:first, :conditions => {}, :sort => [[:_id, :asc]])
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
        WillPaginate::Collection.create(criteria.page, criteria.per_page, 0) do |pager|
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

    # Performs equality checking on the attributes.
    def ==(other)
      return false unless other.is_a?(Document)
      @attributes.except(:modified_at).except(:created_at) ==
        other.attributes.except(:modified_at).except(:created_at)
    end

    # Get the Mongo::Collection associated with this Document.
    def collection
      self.class.collection
    end

    # Returns the class defaults
    def defaults
      self.class.defaults
    end

    # Return true if the +Document+ is embedded in another +Document+.
    def embedded?
      self.class.embedded?
    end

    # Get the fields for the Document class.
    def fields
      self.class.fields
    end

    # Get the id associated with this object.
    # This is in essence the primary key.
    def id
      @attributes[:_id]
    end

    # Set the id
    def id=(new_id)
      @attributes[:_id] = new_id
    end

    alias :_id :id
    alias :_id= :id=

    # Instantiate a new Document, setting the Document's attributes if given.
    # If no attributes are provided, they will be initialized with an empty Hash.
    def initialize(attrs = {})
      process(defaults.merge(attrs))
      @new_record = true if id.nil?
      generate_key
    end

    def inspect
      "#{self.class.name} : #{@attributes.inspect}"
    end

    # Return the +Document+ primary key.
    def primary_key
      self.class.primary_key
    end

    # Returns true is the Document has not been persisted to the database, false if it has.
    def new_record?
      @new_record == true
    end

    # Notify observers that this Document has changed.
    def notify
      changed(true)
      notify_observers(self)
    end

    # Sets the parent object
    def parentize(object, association_name)
      self.parent = object
      self.association_name = association_name
      add_observer(object)
    end

    # Read from the attributes hash.
    def read_attribute(name)
      fields[name].get(@attributes[name])
    end

    # Reloads the +Document+ attributes from the database.
    def reload
      @attributes = collection.find_one(:_id => id).with_indifferent_access
    end

    # Return the root +Document+ in the object graph.
    def root
      object = self
      while (object.parent) do object = object.parent; end
      object || self
    end

    # Returns the id of the Document
    def to_param
      id.to_s
    end

    # Update the document based on notify from child
    def update(child, clear = false)
      @attributes.insert(child.association_name, child.attributes) unless clear
      @attributes.delete(child.association_name) if clear
      notify
    end

    # Write to the attributes hash.
    def write_attribute(name, value)
      run_callbacks(:before_update)
      @attributes[name] = fields[name].set(value)
      run_callbacks(:after_update)
      notify
    end

    # Writes all the attributes of this Document, and delegate up to
    # the parent.
    def write_attributes(attrs)
      process(attrs)
      notify
    end

    private
    def generate_key
      if primary_key
        values = primary_key.collect { |key| @attributes[key] }
        @attributes[:_id] = values.join(" ").parameterize.to_s
      else
        @attributes[:_id] = Mongo::ObjectID.new.to_s unless id
      end
    end
  end
end
