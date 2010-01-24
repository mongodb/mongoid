# encoding: utf-8
module Mongoid #:nodoc:
  module Associations #:nodoc:
    class HasMany
      include Proxy

      attr_accessor :association_name, :klass

      # Appends the object to the +Array+, setting its parent in
      # the process.
      def <<(*objects)
        objects.flatten.each do |object|
          object.parentize(@parent, @association_name)
          @target << object
          object.notify
        end
      end

      alias :concat :<<
      alias :push :<<

      # Clears the association, and notifies the parents of the removal.
      def clear
        unless @target.empty?
          object = @target.first
          object.changed(true)
          object.notify_observers(object, true)
          @target.clear
        end
      end

      # Builds a new Document and adds it to the association collection. The
      # document created will be of the same class as the others in the
      # association, and the attributes will be passed into the constructor.
      #
      # Returns:
      #
      # The newly created Document.
      def build(attrs = {}, type = nil)
        object = type ? type.instantiate : @klass.instantiate
        object.parentize(@parent, @association_name)
        object.write_attributes(attrs)
        @target << object
        object
      end

      # Creates a new Document and adds it to the association collection. The
      # document created will be of the same class as the others in the
      # association, and the attributes will be passed into the constructor and
      # the new object will then be saved.
      #
      # Returns:
      #
      # Rhe newly created Document.
      def create(attrs = {}, type = nil)
        object = build(attrs, type)
        object.save
        object
      end

      # Finds a document in this association.
      #
      # If :all is passed, returns all the documents
      #
      # If an id is passed, will return the document for that id.
      #
      # Returns:
      #
      # Array or single Document.
      def find(param)
        return @target if param == :all
        return detect { |document| document.id == param }
      end

      # Creates the new association by finding the attributes in
      # the parent document with its name, and instantiating a
      # new document for each one found. These will then be put in an
      # internal array.
      #
      # This then delegated all methods to the array class since this is
      # essentially a proxy to an array itself.
      #
      # Options:
      #
      # parent: The parent document to the association.
      # options: The association options.
      def initialize(parent, options)
        @parent, @association_name = parent, options.name
        @klass, @options = options.klass, options
        initialize_each(parent.raw_attributes[@association_name])
      end

      # If the target array does not respond to the supplied method then try to
      # find a named scope or criteria on the class and send the call there.
      #
      # If the method exists on the array, use the default proxy behavior.
      def method_missing(name, *args, &block)
        unless @target.respond_to?(name)
          criteria = @klass.send(name, *args)
          criteria.documents = @target
          return criteria
        end
        super
      end

      # Used for setting associations via a nested attributes setter from the
      # parent +Document+.
      #
      # Options:
      #
      # attributes: A +Hash+ of integer keys and +Hash+ values.
      #
      # Returns:
      #
      # The newly build target Document.
      def nested_build(attributes)
        attributes.values.each do |attrs|
          build(attrs)
        end
      end

      protected
      # Initializes each of the attributes in the hash.
      def initialize_each(attributes)
        @target = attributes ? attributes.collect do |attrs|
          klass = attrs.klass
          child = klass ? klass.instantiate(attrs) : @klass.instantiate(attrs)
          child.parentize(@parent, @association_name)
          child
        end : []
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
          instantiate(parent, options)
        end
      end

    end
  end
end
