# frozen_string_literal: true

module Mongoid
  module Association
    module Nested
      # Mixin module containing common functionality used to
      # perform #accepts_nested_attributes_for attribute assignment
      # on associations.
      module Buildable
        attr_accessor :attributes, :existing, :association, :options

        # Determines if destroys are allowed for this document.
        #
        # @example Do we allow a destroy?
        #   builder.allow_destroy?
        #
        # @return [ true | false ] True if the allow destroy option was set.
        def allow_destroy?
          options[:allow_destroy] || false
        end

        # Returns the reject if option defined with the macro.
        #
        # @example Is there a reject proc?
        #   builder.reject?
        #
        # @param [ Document ] document The parent document of the association
        # @param [ Hash ] attrs The attributes to check for rejection.
        #
        # @return [ true | false ] True and call proc or method if rejectable, false if not.
        def reject?(document, attrs)
          case callback = options[:reject_if]
          when Symbol
            (document.method(callback).arity == 0) ? document.send(callback) : document.send(callback, attrs)
          when Proc
            callback.call(attrs)
          else
            false
          end
        end

        # Determines if only updates can occur. Only valid for one-to-one
        # associations.
        #
        # @example Is this update only?
        #   builder.update_only?
        #
        # @return [ true | false ] True if the update_only option was set.
        def update_only?
          options[:update_only] || false
        end

        # Convert an id to its appropriate type.
        #
        # @example Convert the id.
        #   builder.convert_id(Person, "4d371b444835d98b8b000010")
        #
        # Ids arriving from a form are always scalars. A Hash or an Array
        # here means the parameters were crafted, and letting one through
        # would turn the id into a query operator, so they are rejected.
        #
        # @param [ Class ] klass The class we're trying to convert for.
        # @param [ String ] id The id, usually coming from the form.
        #
        # @return [ BSON::ObjectId | String | Object ] The converted id.
        #
        # @raise [ Errors::DocumentNotFound ] if the id is not a scalar, or
        #   cannot be converted to the type the class uses for its ids.
        #   The BSON::Error rescue is defensive: a value that reaches
        #   BSON::ObjectId.mongoize and raises there must not surface as an
        #   unhandled BSON error in the caller.
        def convert_id(klass, id)
          raise Errors::DocumentNotFound.new(klass, id) if id.is_a?(::Hash) || id.is_a?(::Array)

          klass.using_object_ids? ? BSON::ObjectId.mongoize(id) : id
        rescue BSON::Error
          raise Errors::DocumentNotFound.new(klass, id)
        end

        private

        # Get the id attribute from the given hash, whether it's
        # prefixed with an underscore or is a symbol.
        #
        # @example Get the id.
        #   extract_id({ _id: 1 })
        #
        # @param [ Hash ] hash The hash from which to extract.
        #
        # @return [ Object ] The value of the id.
        def extract_id(hash)
          hash['_id'] || hash[:_id] || hash['id'] || hash[:id]
        end

        # Deletes the id key from the given hash.
        #
        # @example Delete an id value.
        #   delete_id({ "_id" => 1 })
        #
        # @param [ Hash ] hash The hash from which to delete.
        #
        # @return [ Object ] The deleted value, or nil.
        def delete_id(hash)
          hash.delete('_id') || hash.delete(:_id) || hash.delete('id') || hash.delete(:id)
        end
      end
    end
  end
end
