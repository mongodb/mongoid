# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    module Builders #:nodoc:
      module NestedAttributes #:nodoc:
        class One

          attr_accessor :attributes, :destroy, :existing, :metadata, :options

          # Determines if destroys are allowed for this document.
          #
          # Example:
          #
          # <tt>one.allow_destroy?</tt>
          #
          # Returns:
          #
          # True if the allow destroy option was set.
          def allow_destroy?
            options[:allow_destroy] != false
          end

          # Create the new builder for nested attributes on one-to-one
          # relations.
          #
          # Example:
          #
          # <tt>One.new(metadata, attributes, options)</tt>
          #
          # Options:
          #
          # metadata: The relation metadata
          # attributes: The attributes hash to attempt to set.
          # options: The options defined.
          #
          # Returns:
          #
          # A new builder.
          def initialize(metadata, attributes, options)
            @attributes = attributes.with_indifferent_access
            @metadata = metadata
            @options = options
            @destroy = attributes.delete(:_destroy)
          end

          # Builds the relation depending on the attributes and the options
          # passed to the macro.
          #
          # This attempts to perform 3 operations, either one of an update of
          # the existing relation, a replacement of the relation with a new
          # document, or a removal of the relation.
          #
          # Example:
          #
          # <tt>one.build(person)</tt>
          #
          # Options:
          #
          # parent: The parent document of the relation.
          def build(parent)
            @existing = parent.send(metadata.name)
            if update?
              existing.attributes = attributes
            elsif replace?
              parent.send(metadata.setter, metadata.klass.new(attributes))
            elsif delete?
              parent.send(metadata.setter, nil)
            end
          end

          private

          # Can the existing relation be deleted?
          #
          # Example:
          #
          # <tt>delete?</tt>
          #
          # Returns:
          #
          # True if the relation should be deleted.
          def delete?
            destroyable? && !attributes[:_id].nil?
          end

          # Can the existing relation potentially be deleted?
          #
          # Example:
          #
          # <tt>destroyable?</tt>
          #
          # Returns:
          #
          # True if the relation can potentially be deleted.
          def destroyable?
            [ 1, "1", true, "true" ].include?(destroy) && allow_destroy?
          end

          # Is the id in the attribtues acceptable for allowing an update to
          # the existing relation?
          #
          # Example:
          #
          # <tt>acceptable_id?</tt>
          #
          # Returns:
          #
          # True if the id part of the logic will allow an update.
          def acceptable_id?
            id = attributes[:_id]
            existing.id == id || id.nil? || (existing.id != id && update_only?)
          end

          # Returns the reject if option defined with the macro.
          #
          # Example:
          #
          # <tt>reject_if?</tt>
          #
          # Returns:
          #
          # True if rejectable.
          def reject_if?
            options[:reject_if]
          end

          # Is the document to be replaced?
          #
          # Example:
          #
          # <tt>replace?</tt>
          #
          # Returns:
          #
          # True if the document should be replaced.
          def replace?
            !existing && !destroyable? && !attributes.blank?
          end

          # Should the document be updated?
          #
          # Example:
          #
          # <tt>update?</tt>
          #
          # Returns:
          #
          # True if the object should have its attributes updated.
          def update?
            existing && !destroyable? && acceptable_id?
          end

          # Is this an update only situation?
          #
          # Example:
          #
          # <tt>update_only?</tt>
          #
          # Returns:
          #
          # True if the update_only option was set.
          def update_only?
            !!options[:update_only]
          end
        end
      end
    end
  end
end
