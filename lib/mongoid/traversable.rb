# frozen_string_literal: true

require 'mongoid/fields/validators/macro'

module Mongoid
  # Mixin module included in Mongoid::Document to provide behavior
  # around traversing the document graph.
  module Traversable
    extend ActiveSupport::Concern

    # Class-level methods for the Traversable behavior.
    module ClassMethods
      # Determines if the document is a subclass of another document.
      #
      # @example Check if the document is a subclass.
      #   Square.hereditary?
      #
      # @return [ true | false ] True if hereditary, false if not.
      def hereditary?
        !!(superclass < Mongoid::Document)
      end

      # When inheriting, we want to copy the fields from the parent class and
      # set the on the child to start, mimicking the behavior of the old
      # class_inheritable_accessor that was deprecated in Rails edge.
      #
      # @example Inherit from this class.
      #   Person.inherited(Doctor)
      #
      # @param [ Class ] subclass The inheriting class.
      #
      # rubocop:disable Metrics/AbcSize
      def inherited(subclass)
        super
        @_type = nil
        subclass.aliased_fields = aliased_fields.dup
        subclass.localized_fields = localized_fields.dup
        subclass.fields = fields.dup
        subclass.pre_processed_defaults = pre_processed_defaults.dup
        subclass.post_processed_defaults = post_processed_defaults.dup
        subclass._declared_scopes = Hash.new { |_hash, key| _declared_scopes[key] }
        subclass.discriminator_value = subclass.name

        # We need to do this here because the discriminator_value method is
        # overridden in the subclass above.
        subclass.include DiscriminatorRetrieval

        # We only need the _type field if inheritance is in play, but need to
        # add to the root class as well for backwards compatibility.
        return if fields.key?(discriminator_key)

        default_proc = -> { self.class.discriminator_value }
        field(discriminator_key, default: default_proc, type: String)
      end
      # rubocop:enable Metrics/AbcSize
    end

    # `_parent` is intentionally not implemented via attr_accessor because
    # of the need to use a double underscore for the instance variable.
    # Associations automatically create backing variables prefixed with a
    # single underscore, which would conflict with this accessor if a model
    # were to declare a `parent` association.

    # Retrieves the parent document of this document.
    #
    # @return [ Mongoid::Document | nil ] the parent document
    #
    # @api private
    def _parent
      @__parent || nil
    end

    # Sets the parent document of this document.
    #
    # @param [ Mongoid::Document | nil ] document the document to set as
    #   the parent document.
    #
    # @returns [ Mongoid::Document ] The parent document.
    #
    # @api private
    def _parent=(document)
      @__parent = document
    end

    # Module used for prepending to the various discriminator_*= methods
    #
    # @api private
    module DiscriminatorAssignment
      # Sets the discriminator key.
      #
      # @param [ String ] value The discriminator key to set.
      #
      # @api private
      # rubocop:disable Metrics/AbcSize
      def discriminator_key=(value)
        raise Errors::InvalidDiscriminatorKeyTarget.new(self, superclass) if hereditary?

        _mongoid_clear_types

        if value
          Mongoid::Fields::Validators::Macro.validate_field_name(self, value)
          value = value.to_s
          super
        else
          # When discriminator key is set to nil, replace the class's definition
          # of the discriminator key reader (provided by class_attribute earlier)
          # and re-delegate to Mongoid.
          class << self
            delegate :discriminator_key, to: ::Mongoid
          end
        end

        # This condition checks if the new discriminator key would overwrite
        # an existing field.
        # This condition also checks if the class has any descendants, because
        # if it doesn't then it doesn't need a discriminator key.
        return unless !fields.key?(discriminator_key) && !descendants.empty?

        default_proc = -> { self.class.discriminator_value }
        field(discriminator_key, default: default_proc, type: String)
      end
      # rubocop:enable Metrics/AbcSize

      # Returns the discriminator key.
      #
      # @return [ String ] The discriminator key.
      #
      # @api private
      def discriminator_value=(value)
        value ||= name
        _mongoid_clear_types
        add_discriminator_mapping(value)
        @discriminator_value = value
      end
    end

    # Module used for prepending the discriminator_value method.
    #
    # A separate module was needed because the subclasses of this class
    # need to be manually prepended with the discriminator_value and can't
    # rely on being a class_attribute because the .discriminator_value
    # method is overridden by every subclass in the inherited method.
    #
    # @api private
    module DiscriminatorRetrieval
      # Get the name on the reading side if the discriminator_value is nil
      def discriminator_value
        @discriminator_value || name
      end
    end

    included do
      class_attribute :discriminator_key, instance_accessor: false

      class << self
        delegate :discriminator_key, to: ::Mongoid
        prepend DiscriminatorAssignment
        include DiscriminatorRetrieval

        # @api private
        #
        # @return [ Hash<String, Class> ] The current mapping of discriminator_values to classes
        attr_accessor :discriminator_mapping
      end

      # Add a discriminator mapping to the parent class. This mapping is used when
      # receiving a document to identify its class.
      #
      # @param [ String ] value The discriminator_value that was just set
      # @param [ Class ] The class the discriminator_value was set on
      #
      # @api private
      def self.add_discriminator_mapping(value, klass = self)
        self.discriminator_mapping ||= {}
        self.discriminator_mapping[value] = klass
        superclass.add_discriminator_mapping(value, klass) if hereditary?
      end

      # Get the discriminator mapping from the parent class. This method returns nil if there
      # is no mapping for the given value.
      #
      # @param [ String ] value The discriminator_value to retrieve
      #
      # @return [ Class | nil ] klass The class corresponding to the given discriminator_value. If
      #                               the value is not in the mapping, this method returns nil.
      #
      # @api private
      def self.get_discriminator_mapping(value)
        self.discriminator_mapping[value] if self.discriminator_mapping
      end
    end

    # Get all child +Documents+ to this +Document+
    #
    # @return [ Array<Document> ] All child documents in the hierarchy.
    #
    # @api private
    def _children(reset: false)
      # See discussion above for the `_parent` method, as to why the variable
      # here needs to have two underscores.
      #
      # rubocop:disable Naming/MemoizedInstanceVariableName
      if reset
        @__children = nil
      else
        @__children ||= collect_children
      end
      # rubocop:enable Naming/MemoizedInstanceVariableName
    end

    # Get all descendant +Documents+ of this +Document+ recursively.
    # This is used when calling update persistence operations from
    # the root document, where changes in the entire tree need to be
    # determined. Note that persistence from the embedded documents will
    # always be preferred, since they are optimized calls... This operation
    # can get expensive in domains with large hierarchies.
    #
    # @return [ Array<Document> ] All descendant documents in the hierarchy.
    #
    # @api private
    def _descendants(reset: false)
      # See discussion above for the `_parent` method, as to why the variable
      # here needs to have two underscores.
      #
      # rubocop:disable Naming/MemoizedInstanceVariableName
      if reset
        @__descendants = nil
      else
        @__descendants ||= collect_descendants
      end
      # rubocop:enable Naming/MemoizedInstanceVariableName
    end

    # Collect all the children of this document.
    #
    # @return [ Array<Document> ] The children.
    #
    # @api private
    def collect_children
      [].tap do |children|
        embedded_relations.each_pair do |name, _association|
          without_autobuild do
            child = send(name)
            children.concat(Array.wrap(child)) if child
          end
        end
      end
    end

    # Collect all the descendants of this document.
    #
    # @return [ Array<Document> ] The descendants.
    #
    # @api private
    def collect_descendants
      children = []
      to_expand = _children
      expanded = {}

      until to_expand.empty?
        expanding = to_expand
        to_expand = []
        expanding.each do |child|
          next if expanded[child]

          # Don't mark expanded if _id is nil, since documents are compared by
          # their _ids, multiple embedded documents with nil ids will compare
          # equally, and some documents will not be expanded.
          expanded[child] = true if child._id
          children << child
          to_expand += child._children
        end
      end

      children
    end

    # Marks all descendants as being persisted.
    #
    # @return [ Array<Document> ] The flagged descendants.
    def flag_descendants_persisted
      _descendants.each do |child|
        child.new_record = false
      end
    end

    # Determines if the document is a subclass of another document.
    #
    # @example Check if the document is a subclass
    #   Square.new.hereditary?
    #
    # @return [ true | false ] True if hereditary, false if not.
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
    def remove_child(child)
      name = child.association_name
      if child.embedded_one?
        attributes.delete(child._association.store_as)
        remove_ivar(name)
      else
        relation = send(name)
        relation._remove(child)
      end
    end

    # After descendants are persisted we can call this to move all their
    # changes and flag them as persisted in one call.
    #
    # @return [ Array<Document> ] The descendants.
    def reset_persisted_descendants
      _descendants.each do |child|
        child.move_changes
        child.new_record = false
      end
      _reset_memoized_descendants!
    end

    # Resets the memoized descendants on the object. Called internally when an
    # embedded array changes size.
    #
    # @return [ nil ] nil.
    #
    # @api private
    def _reset_memoized_descendants!
      _parent&._reset_memoized_descendants!
      _children reset: true
      _descendants reset: true
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
      object = object._parent while object._parent
      object
    end

    # Is this document the root document of the hierarchy?
    #
    # @example Is the document the root?
    #   document._root?
    #
    # @return [ true | false ] If the document is the root.
    def _root?
      _parent ? false : true
    end
  end
end
