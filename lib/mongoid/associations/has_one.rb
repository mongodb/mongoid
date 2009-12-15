# encoding: utf-8
module Mongoid #:nodoc:
  module Associations #:nodoc:
    class HasOne #:nodoc:
      instance_methods.each do |method|
        undef_method(method) unless method =~ /(^__|^nil\?$|^send$|^object_id$)/
      end

      attr_reader :association_name, :document, :parent, :options

      # Build a new object for the association.
      def build(attributes)
        @document = attributes.assimilate(@parent, @options)
        self
      end

      # Create a new object for the association and save it.
      def create(attributes)
        build(attributes)
        @document.save
        self
      end

      # Creates the new association by finding the attributes in
      # the parent document with its name, and instantiating a
      # new document for it.
      #
      # All method calls on this object will then be delegated
      # to the internal document itself.
      #
      # Options:
      #
      # document: The parent +Document+
      # attributes: The attributes of the decorated object.
      # options: The association options.
      def initialize(document, attributes, options)
        @parent, @options, @association_name = document, options, options.name
        unless attributes.nil?
          @document = attributes.assimilate(@parent, @options)
        end
      end

      # Delegate all missing methods over to the +Document+.
      def method_missing(name, *args)
        @document.send(name, *args)
      end

      # Used for setting the association via a nested attributes setter on the
      # parent +Document+.
      def nested_build(attributes)
        build(attributes)
      end

      # Need to override here for when the underlying document is nil.
      def valid?
        @document ? @document.valid? : false
      end

      class << self
        # Preferred method of instantiating a new +HasOne+, since nil values
        # will be handled properly.
        #
        # Options:
        #
        # document: The parent +Document+
        # options: The association options.
        def instantiate(document, options)
          attributes = document.attributes[options.name]
          new(document, attributes, options)
        end

        # Returns the macro used to create the association.
        def macro
          :has_one
        end

        # Perform an update of the relationship of the parent and child. This
        # will assimilate the child +Document+ into the parent's object graph.
        #
        # Options:
        #
        # child: The child +Document+ or +Hash+.
        # parent: The parent +Document+ to update.
        # options: The association +Options+
        #
        # Example:
        #
        # <tt>HasOne.update({:first_name => "Hank"}, person, options)</tt>
        def update(child, parent, options)
          child.assimilate(parent, options)
        end
      end

    end
  end
end
