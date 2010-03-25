# encoding: utf-8
module Mongoid #:nodoc:
  module Document
    extend ActiveSupport::Concern
    included do
      include Mongoid::Components

      cattr_accessor :_collection, :collection_name, :embedded, :primary_key, :hereditary

      self.embedded = false
      self.hereditary = false
      self.collection_name = self.name.collectionize

      attr_accessor :association_name, :_parent
      attr_reader :new_record

      delegate :collection, :db, :embedded, :primary_key, :to => "self.class"
    end

    module ClassMethods
      # Return the database associated with this class.
      def db
        collection.db
      end

      # Returns the collection associated with this +Document+. If the
      # document is embedded, there will be no collection associated
      # with it.
      #
      # Returns: <tt>Mongo::Collection</tt>
      def collection
        raise Errors::InvalidCollection.new(self) if embedded
        self._collection ||= Mongoid::Collection.new(self, self.collection_name)
        add_indexes; self._collection
      end

      # Perform default behavior but mark the hierarchy as being hereditary.
      def inherited(subclass)
        super(subclass)
        self.hereditary = true
      end

      # Instantiate a new object, only when loaded from the database or when
      # the attributes have already been typecast.
      #
      # Example:
      #
      # <tt>Person.instantiate(:title => "Sir", :age => 30)</tt>
      def instantiate(attrs = nil, allocating = false)
        attributes = attrs || {}
        if attributes["_id"] || allocating
          document = allocate
          document.instance_variable_set(:@attributes, attributes)
          document.setup_modifications
          return document
        else
          return new(attrs)
        end
      end

      # Defines the field that will be used for the id of this +Document+. This
      # set the id of this +Document+ before save to a parameterized version of
      # the field that was supplied. This is good for use for readable URLS in
      # web applications.
      #
      # Example:
      #
      #   class Person
      #     include Mongoid::Document
      #     key :first_name, :last_name
      #   end
      def key(*fields)
        self.primary_key = fields
        before_save :identify
      end

      # Macro for setting the collection name to store in.
      #
      # Example:
      #
      # <tt>Person.store_in :populdation</tt>
      def store_in(name)
        self.collection_name = name.to_s
        self._collection = Mongoid::Collection.new(self, name.to_s)
      end

      # Returns all types to query for when using this class as the base.
      def _types
        @_type ||= (subclasses_of(self).map { |o| o.to_s } + [ self.name ])
      end

      # return the list of subclassses for an object
      def subclasses_of(*superclasses) #:nodoc:
        subclasses = []

        superclasses.each do |sup|
          ObjectSpace.each_object(class << sup; self; end) do |k|
            if k != sup && (k.name.blank? || eval("defined?(::#{k}) && ::#{k}.object_id == k.object_id"))
              subclasses << k
            end
          end
        end

        subclasses
      end
    end

    module InstanceMethods
      # Performs equality checking on the attributes. For now we chack against
      # all attributes excluding timestamps on the object.
      def ==(other)
        return false unless other.is_a?(Document)
        attributes.except(:modified_at).except(:created_at) ==
          other.attributes.except(:modified_at).except(:created_at)
      end

      # Delegates to ==
      def eql?(comparison_object)
        self == (comparison_object)
      end

      # Delegates to id in order to allow two records of the same type and id to work with something like:
      #   [ Person.find(1), Person.find(2), Person.find(3) ] & [ Person.find(1), Person.find(4) ] # => [ Person.find(1) ]
      def hash
        id.hash
      end

      # Introduces a child object into the +Document+ object graph. This will
      # set up the relationships between the parent and child and update the
      # attributes of the parent +Document+.
      #
      # Options:
      #
      # parent: The +Document+ to assimilate with.
      # options: The association +Options+ for the child.
      def assimilate(parent, options)
        parentize(parent, options.name); notify; self
      end

      # Return the attributes hash with indifferent access.
      def attributes
        @attributes.with_indifferent_access
      end

      # Clone the current +Document+. This will return all attributes with the
      # exception of the document's id and versions.
      def clone
        self.class.instantiate(@attributes.except("_id").except("versions").dup, true)
      end

      # Generate an id for this +Document+.
      def identify
        Identity.create(self)
      end

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
      def initialize(attrs = nil)
        @attributes = {}
        process(attrs)
        @attributes = attributes_with_defaults(@attributes)
        @new_record = true if id.nil?
        document = yield self if block_given?
        identify
      end

      # Returns the class name plus its attributes.
      def inspect
        attrs = fields.map { |name, field| "#{name}: #{@attributes[name].inspect}" } * ", "
        "#<#{self.class.name} _id: #{id}, #{attrs}>"
      end

      # Notify observers of an update.
      #
      # Example:
      #
      # <tt>person.notify</tt>
      def notify
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
        self._parent = object
        self.association_name = association_name.to_s
        add_observer(object)
      end

      # Return the attributes hash.
      def raw_attributes
        @attributes
      end

      # Reloads the +Document+ attributes from the database.
      def reload
        @attributes = collection.find_one(:_id => id)
        self
      end

      # Remove a child document from this parent +Document+. Will reset the
      # memoized association and notify the parent of the change.
      def remove(child)
        name = child.association_name
        reset(name) { @attributes.remove(name, child.raw_attributes) }
        notify
      end

      # Return the root +Document+ in the object graph. If the current +Document+
      # is the root object in the graph it will return self.
      def _root
        object = self
        while (object._parent) do object = object._parent; end
        object || self
      end

      # Return an array with this +Document+ only in it.
      def to_a
        [ self ]
      end

      # Return this document as a JSON string. Nothing special is required here
      # since Mongoid bubbles up all the child associations to the parent
      # attribute +Hash+ using observers throughout the +Document+ lifecycle.
      #
      # Example:
      #
      # <tt>person.to_json</tt>
      def to_json(options = nil)
        attributes.to_json(options)
      end

      # Return an object to be encoded into a JSON string.
      # Used by Rails 3's object->JSON chain to create JSON
      # in a backend-agnostic way
      #
      # Example:
      #
      # <tt>person.as_json</tt>
      def as_json(options = nil)
        attributes
      end

      # Return this document as an object to be encoded as JSON,
      # with any particular items modified on a per-encoder basis.
      # Nothing special is required here since Mongoid bubbles up
      # all the child associations to the parent attribute +Hash+
      # using observers throughout the +Document+ lifecycle.
      #
      # Example:
      #
      # <tt>person.encode_json(encoder)</tt>
      def encode_json(encoder)
        attributes
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
      # This will also cause the observing +Document+ to notify it's parent if
      # there is any.
      def update(child, clear = false)
        name = child.association_name
        attrs = child.instance_variable_get(:@attributes)
        clear ? @attributes.delete(name) : @attributes.insert(name, attrs)
        notify
      end

      protected
      # apply default values to attributes - calling procs as required
      def attributes_with_defaults(attributes = {})
        default_values = defaults.merge(attributes)
        default_values.each_pair do |key, val|
          default_values[key] = val.call if val.respond_to?(:call)
        end
      end
    end
  end
end
