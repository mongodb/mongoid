# frozen_string_literal: true

module Mongoid
  module Association

    # Superclass for all objects that bind associations together.
    module Bindable
      include Threaded::Lifecycle

      attr_reader :_base, :_target, :_association

      # Create the new binding.
      #
      # @example Initialize a binding.
      #   Binding.new(base, target, association)
      #
      # @param [ Document ] base The base of the binding.
      # @param [ Document | Array<Document> ] target The target of the binding.
      # @param [ Association ] association The association metadata.
      def initialize(base, target, association)
        @_base, @_target, @_association = base, target, association
      end

      # Execute the provided block inside a binding.
      #
      # @example Execute the binding block.
      #   binding.binding do
      #     base.foreign_key = 1
      #   end
      #
      # @return [ Object ] The result of the yield.
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
      def check_inverse!(doc)
        unless _association.bindable?(doc)
          raise Errors::InverseNotFound.new(
              _base.class,
              _association.name,
              doc.class,
              _association.foreign_key
          )
        end
      end

      # Remove the associated document from the inverse's association.
      #
      # @param [ Document ] doc The document to remove.
      def remove_associated(doc)
        if inverse = _association.inverse(doc)
          if _association.many?
            remove_associated_many(doc, inverse)
          elsif _association.in_to?
            remove_associated_in_to(doc, inverse)
          end
        end
      end

      # Remove the associated document from the inverse's association.
      #
      # This method removes the associated on *_many relationships.
      #
      # @param [ Document ] doc The document to remove.
      # @param [ Symbol ] inverse The name of the inverse.
      def remove_associated_many(doc, inverse)
        # We only want to remove the inverse association when the inverse
        # document is in memory.
        if inv = doc.ivar(inverse)
          # This first condition is needed because when assigning the
          # embeds_many association using the same embeds_many
          # association, we delete from the array we are about to assign.
          if _base != inv && (associated = inv.ivar(_association.name))
            associated.delete(doc)
          end
        end
      end

      # Remove the associated document from the inverse's association.
      #
      # This method removes associated on belongs_to and embedded_in
      # associations.
      #
      # @param [ Document ] doc The document to remove.
      # @param [ Symbol ] inverse The name of the inverse.
      def remove_associated_in_to(doc, inverse)
        # We only want to remove the inverse association when the inverse
        # document is in memory.
        if associated = doc.ivar(inverse)
          associated.send(_association.setter, nil)
        end
      end

      # Set the id of the related document in the foreign key field on the
      # keyed document.
      #
      # @api private
      #
      # @example Bind the foreign key.
      #   binding.bind_foreign_key(post, person._id)
      #
      # @param [ Document ] keyed The document that stores the foreign key.
      # @param [ Object ] id The id of the bound document.
      def bind_foreign_key(keyed, id)
        unless keyed.frozen?
          keyed.you_must(_association.foreign_key_setter, id)
        end
      end

      # Set the type of the related document on the foreign type field, used
      # when associations are polymorphic.
      #
      # @api private
      #
      # @example Bind the polymorphic type.
      #   binding.bind_polymorphic_type(post, "Person")
      #
      # @param [ Document ] typed The document that stores the type field.
      # @param [ String ] name The name of the model.
      def bind_polymorphic_type(typed, name)
        if _association.type
          typed.you_must(_association.type_setter, name)
        end
      end

      # Set the type of the related document on the foreign type field, used
      # when associations are polymorphic.
      #
      # @api private
      #
      # @example Bind the polymorphic type.
      #   binding.bind_polymorphic_inverse_type(post, "Person")
      #
      # @param [ Document ] typed The document that stores the type field.
      # @param [ String ] name The name of the model.
      def bind_polymorphic_inverse_type(typed, name)
        if _association.inverse_type
          typed.you_must(_association.inverse_type_setter, name)
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
      def bind_inverse(doc, inverse)
        if doc.respond_to?(_association.inverse_setter)
          doc.you_must(_association.inverse_setter, inverse)
        end
      end

      # Bind the provided document with the base from the parent association.
      #
      # @api private
      #
      # @example Bind the document with the base.
      #   binding.bind_from_relational_parent(doc)
      #
      # @param [ Document ] doc The document to bind.
      def bind_from_relational_parent(doc)
        check_inverse!(doc)
        remove_associated(doc)
        bind_foreign_key(doc, record_id(_base))
        bind_polymorphic_type(doc, _base.class.name)
        bind_inverse(doc, _base)
      end

      def record_id(_base)
        _base.__send__(_association.primary_key)
      end

      # Ensure that the association on the base is correct, for the cases
      # where we have multiple belongs to definitions and were are setting
      # different parents in memory in order.
      #
      # @api private
      #
      # @example Set the base association.
      #   binding.set_base_association
      #
      # @return [ true | false ] If the association changed.
      def set_base_association
        inverse_association = _association.inverse_association(_target)
        if inverse_association != _association && !inverse_association.nil?
          _base._association = inverse_association
        end
      end

      # Bind the provided document with the base from the parent association.
      #
      # @api private
      #
      # @example Bind the document with the base.
      #   unbinding.unbind_from_relational_parent(doc)
      #
      # @param [ Document ] doc The document to unbind.
      def unbind_from_relational_parent(doc)
        check_inverse!(doc)
        bind_foreign_key(doc, nil)
        bind_polymorphic_type(doc, nil)
        bind_inverse(doc, nil)
      end
    end
  end
end
