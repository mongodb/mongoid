# encoding: utf-8
module Mongoid #:nodoc:
  module Associations #:nodoc:
    # Represents an association that is embedded in a parent document as a
    # one-to-one relationship.
    class EmbedsOne < Proxy

      # Build a new object for the association.
      def build(attrs = {}, type = nil)
        @target = attrs.assimilate(@parent, @options, type); self
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
      # attributes: The attributes of the target object.
      # options: The association options.
      #
      # Returns:
      #
      # A new +HashOne+ association proxy.
      def initialize(document, attrs, options, target = nil)
        @parent, @options  = document, options
        @target = target ? target : attrs.assimilate(@parent, @options, attrs.klass)
        extends(options)
      end

      # Used for setting the association via a nested attributes setter on the
      # parent +Document+. Called when using accepts_nested_attributes_for.
      #
      # Options:
      #
      # attributes: The attributes for the new association
      #
      # Returns:
      #
      # A new target document.
      def nested_build(attributes, options = nil)
        unless @target.blank? && options[:update_only]
          @target.write_attributes(attributes)
        end; @target
      end

      class << self
        # Preferred method of instantiating a new +EmbedsOne+, since nil values
        # will be handled properly.
        #
        # Options:
        #
        # document: The parent +Document+
        # options: The association options.
        #
        # Returns:
        #
        # A new +EmbedsOne+ association proxy.
        def instantiate(document, options, target = nil)
          attributes = document.raw_attributes[options.name]
          return nil if attributes.blank? && target.nil?
          new(document, attributes, options, target)
        end

        # Returns the macro used to create the association.
        def macro
          :embeds_one
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
        # <tt>EmbedsOne.update({:first_name => "Hank"}, person, options)</tt>
        #
        # Returns:
        #
        # A new +EmbedsOne+ association proxy.
        def update(child, parent, options)
          child.assimilate(parent, options)
          instantiate(parent, options, child.is_a?(Hash) ? nil : child)
        end
      end
    end
  end
end
