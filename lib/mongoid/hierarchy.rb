# encoding: utf-8
module Mongoid #:nodoc
  module Hierarchy #:nodoc
    extend ActiveSupport::Concern
    included do
      attr_accessor :_parent
    end

    module ClassMethods #:nodoc:

      # Determines if the document is a subclass of another document.
      #
      # @example Check if the document is a subclass.
      #   Square.hereditary?
      #
      # @return [ true, false ] True if hereditary, false if not.
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
      # @example Get all the document's children.
      #   person._children
      #
      # @return [ Array<Document> ] All child documents in the hierarchy.
      def _children
        relations.inject([]) do |children, (name, metadata)|
          children.tap do |kids|
            if metadata.embedded? && name != "versions"
              child = send(name)
              child.to_a.each do |doc|
                kids.push(doc).concat(doc._children)
              end unless child.blank?
            end
          end
        end
      end

      # Determines if the document is a subclass of another document.
      #
      # @example Check if the document is a subclass
      #   Square.new.hereditary?
      #
      # @return [ true, false ] True if hereditary, false if not.
      def hereditary?
        self.class.hereditary?
      end

      # Sets up a child/parent association. This is used for newly created
      # objects so they can be properly added to the graph.
      #
      # @example Set the parent document.
      #   document.parentize(parent)
      #
      # @param [ Document ] document The parent document.
      #
      # @return [ Document ] The parent document.
      def parentize(document)
        self._parent = document
      end

      # Return the root document in the object graph. If the current document
      # is the root object in the graph it will return self.
      #
      # @example Get the root document in the hierarchy.
      #   document._root
      #
      # @return [ Document ] The root document in the hierarchy.
      def _root
        object = self
        while (object._parent) do object = object._parent; end
        object || self
      end
    end
  end
end
