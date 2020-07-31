# frozen_string_literal: true
# encoding: utf-8

require "mongoid/fields/validators/macro"

module Mongoid

  # Provides behavior around traversing the document graph.
  #
  # @since 4.0.0
  module Traversable
    extend ActiveSupport::Concern

    def _parent
      @__parent ||= nil
    end

    def _parent=(p)
      @__parent = p
    end

    # Module used for prepending to the various discriminator_*= methods
    #
    # @api private
    module DiscriminatorAssignment
      def discriminator_key=(value)
        if hereditary?
          raise Errors::InvalidDiscriminatorKeyTarget.new(self, self.superclass)
        end

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
        if !fields.has_key?(self.discriminator_key) && !descendants.empty?
          default_proc = lambda { self.class.discriminator_value }
          field(self.discriminator_key, default: default_proc, type: String)
        end
      end

      def discriminator_value=(value)
        value ||= self.name
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
    # method is overriden by every subclass in the inherited method.
    #
    # @api private
    module DiscriminatorRetrieval

      # Get the name on the reading side if the discriminator_value is nil
      def discriminator_value
        @discriminator_value || self.name
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
      def self.add_discriminator_mapping(value, klass=self)
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
      embedded_relations.each_pair do |name, association|
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
      name = child.association_name
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
      object
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
      # set the on the child to start, mimicking the behavior of the old
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
        subclass.discriminator_value = subclass.name

        # We need to do this here because the discriminator_value method is
        # overriden in the subclass above.
        class << subclass
          include DiscriminatorRetrieval
        end

        # We only need the _type field if inheritance is in play, but need to
        # add to the root class as well for backwards compatibility.
        unless fields.has_key?(self.discriminator_key)
          default_proc = lambda { self.class.discriminator_value }
          field(self.discriminator_key, default: default_proc, type: String)
        end
      end
    end
  end
end
