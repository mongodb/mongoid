# encoding: utf-8
module Mongoid
  module Association
    module Referenced
      module NestedAttributes
        class One < NestedBuilder

          attr_accessor :destroy

          # Builds the relation depending on the attributes and the options
          # passed to the macro.
          #
          # @example Build a 1-1 nested document.
          #   one.build(person, as: :admin)
          #
          # @note This attempts to perform 3 operations, either one of an update of
          #   the existing relation, a replacement of the relation with a new
          #   document, or a removal of the relation.
          #
          # @param [ Document ] parent The parent document.
          #
          # @return [ Document ] The built document.
          #
          # @since 2.0.0
          def build(parent)
            return if reject?(parent, attributes)
            @existing = parent.send(association.name)
            if update?
              attributes.delete_id
              existing.assign_attributes(attributes)
            elsif replace?
              parent.send(association.setter, Factory.build(association.klass, attributes))
            elsif delete?
              parent.send(association.setter, nil)
            end
          end

          # Create the new builder for nested attributes on one-to-one
          # relations.
          #
          # @example Instantiate the builder.
          #   One.new(association, attributes)
          #
          # @param [ Association ] association The association metadata.
          # @param [ Hash ] attributes The attributes hash to attempt to set.
          # @param [ Hash ] options The options defined.
          #
          # @since 2.0.0
          def initialize(association, attributes, options)
            @attributes = attributes.with_indifferent_access
            @association = association
            @options = options
            @destroy = @attributes.delete(:_destroy)
          end

          private

          # Is the id in the attribtues acceptable for allowing an update to
          # the existing relation?
          #
          # @api private
          #
          # @example Is the id acceptable?
          #   one.acceptable_id?
          #
          # @return [ true, false ] If the id part of the logic will allow an update.
          #
          # @since 2.0.0
          def acceptable_id?
            id = convert_id(existing.class, attributes[:id])
            existing._id == id || id.nil? || (existing._id != id && update_only?)
          end

          # Can the existing relation be deleted?
          #
          # @example Can the existing object be deleted?
          #   one.delete?
          #
          # @return [ true, false ] If the relation should be deleted.
          #
          # @since 2.0.0
          def delete?
            destroyable? && !attributes[:id].nil?
          end

          # Can the existing relation potentially be destroyed?
          #
          # @example Is the object destroyable?
          #   one.destroyable?({ :_destroy => "1" })
          #
          # @return [ true, false ] If the relation can potentially be
          #   destroyed.
          #
          # @since 2.0.0
          def destroyable?
            [ 1, "1", true, "true" ].include?(destroy) && allow_destroy?
          end

          # Is the document to be replaced?
          #
          # @example Is the document to be replaced?
          #   one.replace?
          #
          # @return [ true, false ] If the document should be replaced.
          #
          # @since 2.0.0
          def replace?
            !existing && !destroyable? && !attributes.blank?
          end

          # Should the document be updated?
          #
          # @example Should the document be updated?
          #   one.update?
          #
          # @return [ true, false ] If the object should have its attributes updated.
          #
          # @since 2.0.0
          def update?
            existing && !destroyable? && acceptable_id?
          end
        end
      end
    end
  end
end
