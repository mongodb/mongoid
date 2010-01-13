# encoding: utf-8
module Mongoid #:nodoc:
  module Associations #:nodoc:
    class HasMany
      include Proxy

      attr_accessor :association_name, :klass, :options

      # Appends the object to the +Array+, setting its parent in
      # the process.
      def <<(*objects)
        objects.flatten.each do |object|
          object.parentize(@parent, @association_name)
          @documents << object
          object.notify
        end
      end

      # Clears the association, and notifies the parents of the removal.
      def clear
        unless @documents.empty?
          object = @documents.first
          object.changed(true)
          object.notify_observers(object, true)
          @documents.clear
        end
      end

      # Appends the object to the +Array+, setting its parent in
      # the process.
      def concat(*objects)
        self << objects
      end

      # Builds a new Document and adds it to the association collection. The
      # document created will be of the same class as the others in the
      # association, and the attributes will be passed into the constructor.
      #
      # Returns the newly created object.
      def build(attrs = {}, type = nil)
        object = type ? type.instantiate : @klass.instantiate
        object.parentize(@parent, @association_name)
        object.write_attributes(attrs)
        object.identify
        @documents << object
        object
      end

      # Creates a new Document and adds it to the association collection. The
      # document created will be of the same class as the others in the
      # association, and the attributes will be passed into the constructor and
      # the new object will then be saved.
      #
      # Returns the newly created object.
      def create(attrs = {}, type = nil)
        object = build(attrs, type)
        object.save
        object
      end

      # Finds a document in this association.
      # If :all is passed, returns all the documents
      # If an id is passed, will return the document for that id.
      def find(param)
        return @documents if param == :all
        return detect { |document| document.id == param }
      end

      # Creates the new association by finding the attributes in
      # the parent document with its name, and instantiating a
      # new document for each one found. These will then be put in an
      # internal array.
      #
      # This then delegated all methods to the array class since this is
      # essentially a proxy to an array itself.
      def initialize(document, options)
        @parent, @association_name, @klass, @options = document, options.name, options.klass, options
        attributes = document.attributes[@association_name]
        @documents = attributes ? attributes.collect do |attrs|
          type = attrs[:_type]
          child = type ? type.constantize.instantiate(attrs) : @klass.instantiate(attrs)
          child.parentize(@parent, @association_name)
          child
        end : []
      end

      # Delegate all missing methods over to the documents array.
      def method_missing(name, *args, &block)
        @documents.send(name, *args, &block)
      end

      # Used for setting associations via a nested attributes setter from the
      # parent +Document+.
      #
      # Options:
      #
      # attributes: A +Hash+ of integer keys and +Hash+ values.
      def nested_build(attributes)
        attributes.values.each do |attrs|
          build(attrs)
        end
      end

      # Appends the object to the +Array+, setting its parent in
      # the process.
      def push(*objects)
        self << objects
      end

      class << self

        # Preferred method of creating a new +HasMany+ association. It will
        # delegate to new.
        #
        # Options:
        #
        # document: The parent +Document+
        # options: The association options
        def instantiate(document, options)
          new(document, options)
        end

        # Returns the macro used to create the association.
        def macro
          :has_many
        end

        # Perform an update of the relationship of the parent and child. This
        # is initialized by setting the has_many to the supplied +Enumerable+
        # and setting up the parentization.
        def update(children, parent, options)
          parent.remove_attribute(options.name)
          children.assimilate(parent, options)
          new(parent, options)
        end
      end

    end
  end
end
