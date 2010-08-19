# encoding: utf-8
module Mongoid #:nodoc
  module Hierarchy #:nodoc
    extend ActiveSupport::Concern
    included do
      attr_accessor :_parent
    end

    module ClassMethods #:nodoc:
      # Returns <tt>true</tt> if the document inherits from another
      # Mongoid::Document.
      def hereditary?
        Mongoid::Document > superclass
      end
    end

    module InstanceMethods #:nodoc:

      # Get all child +Documents+ to this +Document+, going n levels deep if
      # necessary. This is used when calling update persistence operations from
      # the root document, where changes in the entire tree need to be
      # determined. Note that persistence from the embedded documents will
      # always be preferred, since they are optimized calls... This operation
      # can get expensive in domains with large hierarchies.
      #
      # Example:
      #
      # <tt>person._children</tt>
      #
      # Returns:
      #
      # All child +Documents+ to this +Document+ in the entire hierarchy.
      def _children
        relations.inject([]) do |children, (name, metadata)|
          if metadata.embedded? && name != "versions"
            child = send(name)
            child.to_a.each do |doc|
              children.push(doc).concat(doc._children)
            end unless child.blank?
          end
          children
        end
      end

      # Is inheritance in play here?
      #
      # Returns:
      #
      # <tt>true</tt> if inheritance used, <tt>false</tt> if not.
      def hereditary?
        self.class.hereditary?
      end

      # Sets up a child/parent association. This is used for newly created
      # objects so they can be properly added to the graph.
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
      end

      # Return the root +Document+ in the object graph. If the current +Document+
      # is the root object in the graph it will return self.
      def _root
        object = self
        while (object._parent) do object = object._parent; end
        object || self
      end
    end
  end
end
