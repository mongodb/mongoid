# encoding: utf-8
module Mongoid #:nodoc:
  module Associations #:nodoc:
    class HasOne #:nodoc:
      include Proxy

      attr_reader :association_name, :document, :parent, :options

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
        klass = attributes[:_type] ? attributes[:_type].constantize : nil
        @document = attributes.assimilate(@parent, @options, klass)
      end

      # Delegate all missing methods over to the +Document+.
      def method_missing(name, *args, &block)
        @document.send(name, *args, &block)
      end

      # Used for setting the association via a nested attributes setter on the
      # parent +Document+.
      def nested_build(attributes)
        build(attributes)
      end

      # This will get deprecated
      def to_a
        [@document]
      end

      # Need to override here for when the underlying document is nil.
      def valid?
        @document.valid?
      end

      protected
      # Build a new object for the association.
      def build(attrs = {}, type = nil)
        @document = attrs.assimilate(@parent, @options, type)
        self
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
          return nil if attributes.blank?
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
