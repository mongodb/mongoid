# encoding: utf-8
module Mongoid
  module Relations

    # Superclass for all objects that bind relations together.
    class Binding
      include Threaded::Lifecycle

      attr_reader :base, :target, :metadata

      # Create the new binding.
      #
      # @example Initialize a binding.
      #   Binding.new(base, target, metadata)
      #
      # @param [ Document ] base The base of the binding.
      # @param [ Document, Array<Document> ] target The target of the binding.
      # @param [ Metadata ] metadata The relation's metadata.
      #
      # @since 2.0.0.rc.1
      def initialize(base, target, metadata)
        @base, @target, @metadata = base, target, metadata
      end

      # Execute the provided block inside a binding.
      #
      # @example Execute the binding block.
      #   binding.binding do
      #     base.foreign_key = 1
      #   end
      #
      # @return [ Object ] The result of the yield.
      #
      # @since 3.0.0
      def binding
        unless _binding?
          _binding do
            yield(self) if block_given?
          end
        end
      end

      private

      # Check if the inverse is properly defined.
      #
      # @api private
      #
      # @example Check the inverse definition.
      #   binding.check_inverse!(doc)
      #
      # @param [ Document ] doc The document getting bound.
      #
      # @raise [ Errors::InverseNotFound ] If no inverse found.
      #
      # @since 3.0.0
      def check_inverse!(doc)
        if !metadata.forced_nil_inverse? &&
          !doc.respond_to?(metadata.foreign_key_setter)
          raise Errors::InverseNotFound.new(
            base.class,
            metadata.name,
            doc.class,
            metadata.foreign_key
          )
        end
      end

      # Check for problems with multiple inverse definitions.
      #
      # @api private
      #
      # @example Check for inverses errors.
      #   binding.check_inverses!(doc)
      #
      # @param [ Document ] doc The document to check.
      #
      # @since 3.0.0
      def check_inverses!(doc)
        inverses = metadata.inverses(doc)
        if inverses.count > 1 && base.send(metadata.foreign_key).nil?
          raise Errors::InvalidSetPolymorphicRelation.new(
            metadata.name, base.class.name, target.class.name
          )
        end
      end

      # Set the id of the related document in the foreign key field on the
      # keyed document.
      #
      # @api private
      #
      # @example Bind the foreign key.
      #   binding.bind_foreign_key(post, person.id)
      #
      # @param [ Document ] keyed The document that stores the foreign key.
      # @param [ Object ] id The id of the bound document.
      #
      # @since 3.0.0
      def bind_foreign_key(keyed, id)
        unless keyed.frozen?
          keyed.you_must(metadata.foreign_key_setter, id)
        end
      end

      # Set the type of the related document on the foreign type field, used
      # when relations are polymorphic.
      #
      # @api private
      #
      # @example Bind the polymorphic type.
      #   binding.bind_polymorphic_type(post, "Person")
      #
      # @param [ Document ] typed The document that stores the type field.
      # @param [ String ] name The name of the model.
      #
      # @since 3.0.0
      def bind_polymorphic_type(typed, name)
        if metadata.type
          typed.you_must(metadata.type_setter, name)
        end
      end

      # Set the type of the related document on the foreign type field, used
      # when relations are polymorphic.
      #
      # @api private
      #
      # @example Bind the polymorphic type.
      #   binding.bind_polymorphic_inverse_type(post, "Person")
      #
      # @param [ Document ] typed The document that stores the type field.
      # @param [ String ] name The name of the model.
      #
      # @since 3.0.0
      def bind_polymorphic_inverse_type(typed, name)
        if metadata.inverse_type
          typed.you_must(metadata.inverse_type_setter, name)
        end
      end

      # Bind the inverse document to the child document so that the in memory
      # instances are the same.
      #
      # @api private
      #
      # @example Bind the inverse.
      #   binding.bind_inverse(post, person)
      #
      # @param [ Document ] doc The base document.
      # @param [ Document ] inverse The inverse document.
      #
      # @since 3.0.0
      def bind_inverse(doc, inverse)
        if doc.respond_to?(metadata.inverse_setter)
          doc.you_must(metadata.inverse_setter, inverse)
        end
      end

      # Bind the inverse of field, when in a polymorphic relation.
      #
      # @api private
      #
      # @example Bind the inverse of field.
      #   binding.bind_inverse_of_field(doc)
      #
      # @param [ Document ] doc The document to bind.
      # @param [ String ] name The name of the relation.
      #
      # @since 3.0.0
      def bind_inverse_of_field(doc, name)
        if metadata.inverse_field_bindable?
          if inverse_metadata = metadata.inverse_metadata(doc)
            if setter = inverse_metadata.inverse_of_field_setter
              doc.you_must(setter, name)
            end
          end
        end
      end

      # Bind the provided document with the base from the parent relation.
      #
      # @api private
      #
      # @example Bind the document with the base.
      #   binding.bind_from_relational_parent(doc)
      #
      # @param [ Document ] doc The document to bind.
      #
      # @since 3.0.0
      def bind_from_relational_parent(doc)
        check_inverse!(doc)
        bind_foreign_key(doc, record_id(base))
        bind_polymorphic_type(doc, base.class.name)
        bind_inverse(doc, base)
        bind_inverse_of_field(doc, metadata.name)
      end

      def record_id(base)
        base.__send__(metadata.primary_key)
      end

      # Ensure that the metadata on the base is correct, for the cases
      # where we have multiple belongs to definitions and were are setting
      # different parents in memory in order.
      #
      # @api private
      #
      # @example Set the base metadata.
      #   binding.set_base_metadata
      #
      # @return [ true, false ] If the metadata changed.
      #
      # @since 2.4.4
      def set_base_metadata
        inverse_metadata = metadata.inverse_metadata(target)
        if inverse_metadata != metadata && !inverse_metadata.nil?
          base.metadata = inverse_metadata
        end
      end

      # Bind the provided document with the base from the parent relation.
      #
      # @api private
      #
      # @example Bind the document with the base.
      #   unbinding.unbind_from_relational_parent(doc)
      #
      # @param [ Document ] doc The document to unbind.
      #
      # @since 3.0.0
      def unbind_from_relational_parent(doc)
        check_inverse!(doc)
        bind_foreign_key(doc, nil)
        bind_polymorphic_type(doc, nil)
        bind_inverse(doc, nil)
        bind_inverse_of_field(doc, nil)
      end
    end
  end
end
