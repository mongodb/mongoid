# frozen_string_literal: true

module Mongoid
  module Association
    module Nested
      class One
        include Buildable

        attr_accessor :destroy


        # Builds the association depending on the attributes and the options
        # passed to the macro.
        #
        # @example Build a 1-1 nested document.
        #   one.build(person, as: :admin)
        #
        # @note This attempts to perform 3 operations, either one of an update of
        #   the existing association, a replacement of the association with a new
        #   document, or a removal of the association.
        #
        # @param [ Document ] parent The parent document.
        #
        # @return [ Document ] The built document.
        def build(parent)
          return if reject?(parent, attributes)
          @existing = parent.send(association.name)
          if update?
            attributes.delete_id
            existing.assign_attributes(attributes)
          elsif replace?
            parent.send(association.setter, Factory.build(@class_name, attributes))
          elsif delete?
            parent.send(association.setter, nil)
          else
            check_for_id_violation!
          end
        end

        # Create the new builder for nested attributes on one-to-one
        # associations.
        #
        # @example Instantiate the builder.
        #   One.new(association, attributes)
        #
        # @param [ Association ] association The association metadata.
        # @param [ Hash ] attributes The attributes hash to attempt to set.
        # @param [ Hash ] options The options defined.
        def initialize(association, attributes, options)
          @attributes = attributes.with_indifferent_access
          @association = association
          @options = options
          @class_name = options[:class_name] ? options[:class_name].constantize : association.klass
          @destroy = @attributes.delete(:_destroy)
        end

        private

        # Extracts and converts the id to the expected type.
        #
        # @return [ BSON::ObjectId | String | Object | nil ] The converted id,
        #   or nil if no id is present in the attributes hash.
        def extracted_id
          @extracted_id ||= begin
            id = association.klass.extract_id_field(attributes)
            convert_id(existing.class, id)
          end
        end

        # Is the id in the attributes acceptable for allowing an update to
        # the existing association?
        #
        # @api private
        #
        # @example Is the id acceptable?
        #   one.acceptable_id?
        #
        # @return [ true | false ] If the id part of the logic will allow an update.
        def acceptable_id?
          id = extracted_id
          existing._id == id || id.nil? || (existing._id != id && update_only?)
        end

        # Can the existing association be deleted?
        #
        # @example Can the existing object be deleted?
        #   one.delete?
        #
        # @return [ true | false ] If the association should be deleted.
        def delete?
          id = association.klass.extract_id_field(attributes)
          destroyable? && !id.nil?
        end

        # Can the existing association potentially be destroyed?
        #
        # @example Is the object destroyable?
        #   one.destroyable?({ :_destroy => "1" })
        #
        # @return [ true | false ] If the association can potentially be
        #   destroyed.
        def destroyable?
          Nested::DESTROY_FLAGS.include?(destroy) && allow_destroy?
        end

        # Is the document to be replaced?
        #
        # @example Is the document to be replaced?
        #   one.replace?
        #
        # @return [ true | false ] If the document should be replaced.
        def replace?
          !existing && !destroyable? && !attributes.blank?
        end

        # Should the document be updated?
        #
        # @example Should the document be updated?
        #   one.update?
        #
        # @return [ true | false ] If the object should have its attributes updated.
        def update?
          existing && !destroyable? && acceptable_id?
        end

        # Checks to see if the _id attribute (which is supposed to be
        # immutable) is being asked to change. If so, raise an exception.
        #
        # If Mongoid::Config.immutable_ids is false, this will do nothing,
        # and the update operation will fail silently.
        #
        # @raise [ Errors::ImmutableAttribute ] if _id has changed, and
        #   the document has been persisted.
        def check_for_id_violation!
          # look for the basic criteria of an update (see #update?)
          return unless existing&.persisted? && !destroyable?

          # if the id is either absent, or if it equals the existing record's
          # id, there is no immutability violation.
          id = extracted_id
          return if existing._id == id || id.nil?

          # otherwise, an attempt has been made to set the _id of an existing,
          # persisted document.
          if Mongoid::Config.immutable_ids
            raise Errors::ImmutableAttribute.new(:_id, id)
          else
            Mongoid::Warnings.warn_mutable_ids
          end
        end
      end
    end
  end
end
