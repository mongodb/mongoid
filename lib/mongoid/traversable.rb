# encoding: utf-8
module Mongoid

  # Provides behaviour around traversing the document graph.
  #
  # @since 4.0.0
  module Traversable
    extend ActiveSupport::Concern

    def _parent
      @__parent
    end

    def _parent=(p)
      @__parent = p
    end

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
      @__children ||= collect_children
    end

    # Collect all the children of this document.
    #
    # @example Collect all the children.
    #   document.collect_children
    #
    # @return [ Array<Document> ] The children.
    #
    # @since 2.4.0
    def collect_children
      children = []
      embedded_relations.each_pair do |name, metadata|
        without_autobuild do
          child = send(name)
          Array.wrap(child).each do |doc|
            children.push(doc)
            children.concat(doc._children)
          end if child
        end
      end
      children
    end

    # Marks all children as being persisted.
    #
    # @example Flag all the children.
    #   document.flag_children_persisted
    #
    # @return [ Array<Document> ] The flagged children.
    #
    # @since 3.0.7
    def flag_children_persisted
      _children.each do |child|
        child.new_record = false
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

    # Remove a child document from this parent. If an embeds one then set to
    # nil, otherwise remove from the embeds many.
    #
    # This is called from the +RemoveEmbedded+ persistence command.
    #
    # @example Remove the child.
    #   document.remove_child(child)
    #
    # @param [ Document ] child The child (embedded) document to remove.
    #
    # @since 2.0.0.beta.1
    def remove_child(child)
      name = child.metadata_name
      if child.embedded_one?
        remove_ivar(name)
      else
        relation = send(name)
        relation.send(:delete_one, child)
      end
    end

    # After children are persisted we can call this to move all their changes
    # and flag them as persisted in one call.
    #
    # @example Reset the children.
    #   document.reset_persisted_children
    #
    # @return [ Array<Document> ] The children.
    #
    # @since 2.1.0
    def reset_persisted_children
      _children.each do |child|
        child.move_changes
        child.new_record = false
      end
      _reset_memoized_children!
    end

    # Resets the memoized children on the object. Called internally when an
    # embedded array changes size.
    #
    # @api semiprivate
    #
    # @example Reset the memoized children.
    #   document._reset_memoized_children!
    #
    # @return [ nil ] nil.
    #
    # @since 5.0.0
    def _reset_memoized_children!
      _parent._reset_memoized_children! if _parent
      @__children = nil
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
      object.with(@persistence_options) || self
    end

    # Is this document the root document of the hierarchy?
    #
    # @example Is the document the root?
    #   document._root?
    #
    # @return [ true, false ] If the document is the root.
    #
    # @since 3.1.0
    def _root?
      _parent ? false : true
    end

    module ClassMethods

      # Determines if the document is a subclass of another document.
      #
      # @example Check if the document is a subclass.
      #   Square.hereditary?
      #
      # @return [ true, false ] True if hereditary, false if not.
      def hereditary?
        !!(Mongoid::Document > superclass)
      end

      # When inheriting, we want to copy the fields from the parent class and
      # set the on the child to start, mimicking the behaviour of the old
      # class_inheritable_accessor that was deprecated in Rails edge.
      #
      # @example Inherit from this class.
      #   Person.inherited(Doctor)
      #
      # @param [ Class ] subclass The inheriting class.
      #
      # @since 2.0.0.rc.6
      def inherited(subclass)
        super
        @_type = nil
        subclass.aliased_fields = aliased_fields.dup
        subclass.localized_fields = localized_fields.dup
        subclass.fields = fields.dup
        subclass.pre_processed_defaults = pre_processed_defaults.dup
        subclass.post_processed_defaults = post_processed_defaults.dup
        subclass._declared_scopes = Hash.new { |hash,key| self._declared_scopes[key] }

        # We only need the _type field if inheritance is in play, but need to
        # add to the root class as well for backwards compatibility.
        unless fields.has_key?("_type")
          field(:_type, default: self.name, type: String)
        end
        subclass_default = subclass.name || ->{ self.class.name }
        subclass.field(:_type, default: subclass_default, type: String, overwrite: true)
      end
    end
  end
end
