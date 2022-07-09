# frozen_string_literal: true

module Mongoid
  module Association
    module Nested
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
              document.method(callback).arity == 0 ? document.send(callback) : document.send(callback, attrs)
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
        # @param [ Class ] klass The class we're trying to convert for.
        # @param [ String ] id The id, usually coming from the form.
        #
        # @return [ BSON::ObjectId | String | Object ] The converted id.
        def convert_id(klass, id)
          klass.using_object_ids? ? BSON::ObjectId.mongoize(id) : id
        end
      end
    end
  end
end
