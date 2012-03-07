# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:

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
          keyed.__send__(metadata.foreign_key_setter, id)
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
          typed.__send__(metadata.type_setter, name)
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
        doc.__send__(metadata.inverse_setter, inverse)
      end

      def bind_inverse_of_field(doc, unbind = false)
        if inverse_metadata = metadata.inverse_metadata(doc)
          if setter = inverse_metadata.inverse_of_field_setter
            doc.__send__(setter, unbind ? nil : metadata.name)
          end
        end
      end
    end
  end
end
