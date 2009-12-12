# encoding: utf-8
module Mongoid #:nodoc:
  class Document
    include ActiveSupport::Callbacks
    include Associations, Attributes, Commands, Observable, Validatable
    extend Finders

    attr_accessor :association_name, :parent
    attr_reader :attributes, :new_record

    delegate :collection, :defaults, :embedded?, :fields, :primary_key, :to => :klass

    define_callbacks :before_create, :before_destroy, :before_save, :before_update, :before_validation
    define_callbacks :after_create, :after_destroy, :after_save, :after_update, :after_validation

    class << self

      # Returns the collection associated with this +Document+. If the
      # document is embedded, there will be no collection associated
      # with it.
      #
      # Returns: <tt>Mongo::Collection</tt>
      def collection
        return nil if embedded?
        @collection_name ||= self.to_s.demodulize.tableize
        @collection ||= Mongoid.database.collection(@collection_name)
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
        define(name, options)
        default(name, options)
      end

      # Returns all the fields for the Document as a +Hash+ with names as keys.
      def fields
        @fields
      end

      # Returns a human readable version of the class.
      def human_name
        name.underscore.humanize
      end

      # Adds an index on the field specified. Options can be :unique => true or
      # :unique => false. It will default to the latter.
      def index(name, options = { :unique => false })
        collection.create_index(name, options)
      end

      # Instantiate a new object, only when loaded from the database.
      def instantiate(attrs = {}, allocating = false)
        attributes = attrs.with_indifferent_access
        if attributes[:_id] || allocating
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

      # Returns the primary key field of the +Document+
      def primary_key
        @primary_key
      end

      protected

      # Define a field attribute for the +Document+.
      def define(name, options = {})
        @fields ||= {}.with_indifferent_access
        @fields[name] = Field.new(name.to_s, options)
        define_method(name) { read_attribute(name) }
        define_method("#{name}=") { |value| write_attribute(name, value) }
        define_method("#{name}?") { read_attribute(name) == true } if options[:type] == Boolean
      end

      # Set up a default value for a field.
      def default(name, options = {})
        value = options[:default]
        @defaults ||= {}.with_indifferent_access
        @defaults[name] = value if value
      end

    end

    # Performs equality checking on the attributes. For now we chack against
    # all attributes excluding timestamps on the object.
    def ==(other)
      return false unless other.is_a?(Document)
      @attributes.except(:modified_at).except(:created_at) ==
        other.attributes.except(:modified_at).except(:created_at)
    end

    # Introduces a child object into the +Document+ object graph. This will
    # set up the relationships between the parent and child and update the
    # attributes of the parent +Document+.
    #
    # Options:
    #
    # parent: The +Document+ to assimilate with.
    # options: The association +Options+ for the child.
    #
    # Example:
    #
    # <tt>name.assimilate(person, options)</tt>
    #
    # Returns: The child +Document+.
    def assimilate(parent, options)
      parentize(parent, options.name); notify; self
    end

    # Clone the current +Document+. This will return all attributes with the
    # exception of the document's id and versions.
    def clone
      self.class.instantiate(@attributes.except(:_id).except(:versions).dup, true)
    end

    # Get the id associated with this object. This will pull the _id value out
    # of the attributes +Hash+.
    def id
      @attributes[:_id]
    end

    # Set the id
    def id=(new_id)
      @attributes[:_id] = new_id
    end

    alias :_id :id
    alias :_id= :id=

    # Instantiate a new +Document+, setting the Document's attributes if
    # given. If no attributes are provided, they will be initialized with
    # an empty +Hash+.
    #
    # If a primary key is defined, the document's id will be set to that key,
    # otherwise it will be set to a fresh +Mongo::ObjectID+ string.
    #
    # Options:
    #
    # attrs: The attributes +Hash+ to set up the document with.
    #
    # Example:
    #
    # <tt>Person.new(:title => "Mr", :age => 30)</tt>
    def initialize(attrs = {})
      @attributes = {}.with_indifferent_access
      process(defaults.merge(attrs))
      @new_record = true if id.nil?
      generate_key
    end

    # Returns the class name plus its attributes.
    def inspect
      "#{self.class.name} : #{@attributes.inspect}"
    end

    # Returns true is the +Document+ has not been persisted to the database,
    # false if it has. This is determined by the instance variable @new_record
    # and NOT if the object has an id.
    def new_record?
      @new_record == true
    end

    # Set the changed state of the +Document+ then notify observers that it has changed.
    #
    # Example:
    #
    # <tt>person.notify</tt>
    def notify
      changed(true)
      notify_observers(self)
    end

    # Sets up a child/parent association. This is used for newly created
    # objects so they can be properly added to the graph and have the parent
    # observers set up properly.
    #
    # Options:
    #
    # abject: The parent object that needs to be set for the child.
    # association_name: The name of the association for the child.
    #
    # Example:
    #
    # <tt>address.parentize(person, :addresses)</tt>
    def parentize(object, association_name)
      self.parent = object
      self.association_name = association_name
      add_observer(object)
    end

    # Read a value from the +Document+ attributes. If the value does not exist
    # it will return nil.
    #
    # Options:
    #
    # name: The name of the attribute to get.
    #
    # Example:
    #
    # <tt>person.read_attribute(:title)</tt>
    def read_attribute(name)
      fields[name].get(@attributes[name])
    end

    # Remove a value from the +Document+ attributes. If the value does not exist
    # it will fail gracefully.
    #
    # Options:
    #
    # name: The name of the attribute to remove.
    #
    # Example:
    #
    # <tt>person.remove_attribute(:title)</tt>
    def remove_attribute(name)
      @attributes.delete(name)
    end

    # Reloads the +Document+ attributes from the database.
    def reload
      @attributes = collection.find_one(:_id => id).with_indifferent_access
    end

    # Return the root +Document+ in the object graph. If the current +Document+
    # is the root object in the graph it will return self.
    def root
      object = self
      while (object.parent) do object = object.parent; end
      object || self
    end

    # Returns the id of the Document, used in Rails compatibility.
    def to_param
      id
    end

    # Observe a notify call from a child +Document+. This will either update
    # existing attributes on the +Document+ or clear them out for the child if
    # the clear boolean is provided.
    #
    # Options:
    #
    # child: The child +Document+ that sent the notification.
    # clear: Will clear out the child's attributes if set to true.
    #
    # Example:
    #
    # <tt>person.notify_observers(self)</tt> will cause this method to execute.
    #
    # This will also cause the observing +Document+ to notify it's parent if
    # there is any.
    def update(child, clear = false)
      name = child.association_name
      clear ? @attributes.delete(name) : @attributes.insert(name, child.attributes)
      notify
    end

    # Write a single attribute to the +Document+ attribute +Hash+. This will
    # also fire the before and after update callbacks, and perform any
    # necessary typecasting.
    #
    # Options:
    #
    # name: The name of the attribute to update.
    # value: The value to set for the attribute.
    #
    # Example:
    #
    # <tt>person.write_attribute(:title, "Mr.")</tt>
    #
    # This will also cause the observing +Document+ to notify it's parent if
    # there is any.
    def write_attribute(name, value)
      run_callbacks(:before_update)
      @attributes[name] = fields[name].set(value)
      run_callbacks(:after_update)
      notify
    end

    # Writes the supplied attributes +Hash+ to the +Document+. This will only
    # overwrite existing attributes if they are present in the new +Hash+, all
    # others will be preserved.
    #
    # Options:
    #
    # attrs: The +Hash+ of new attributes to set on the +Document+
    #
    # Example:
    #
    # <tt>person.write_attributes(:title => "Mr.")</tt>
    #
    # This will also cause the observing +Document+ to notify it's parent if
    # there is any.
    def write_attributes(attrs)
      process(attrs)
      notify
    end

    protected
    def generate_key
      if primary_key
        values = primary_key.collect { |key| @attributes[key] }
        @attributes[:_id] = values.join(" ").parameterize.to_s
      else
        @attributes[:_id] = Mongo::ObjectID.new.to_s unless id
      end
    end

    # Convenience method to get the document's class
    def klass
      self.class
    end
  end
end
