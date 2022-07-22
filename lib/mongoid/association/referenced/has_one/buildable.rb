# frozen_string_literal: true

module Mongoid
  module Association
    module Referenced
      class HasOne

        # The Builder behavior for has_one associations.
        module Buildable

          # This method either takes an _id or an object and queries for the
          # inverse side using the id or sets the object after clearing the
          # associated object.
          #
          # @param [ Object ] base The base object.
          # @param [ Object ] object The object to use to build the association.
          # @param [ String ] type The type of the association.
          # @param [ nil ] selected_fields Must be nil.
          #
          # @return [ Document ] A single document.
          def build(base, object, type = nil, selected_fields = nil)
            if query?(object)
              if !base.new_record?
                execute_query(object, base)
              end
            else
              clear_associated(object)
              object
            end
          end

          private

          def clear_associated(object)
            unless inverse
              raise Errors::InverseNotFound.new(
                  @owner_class,
                  name,
                  object.class,
                  foreign_key,
              )
            end
            if object && (associated = object.send(inverse))
              associated.substitute(nil)
            end
          end

          def query_criteria(object, base)
            crit = klass.criteria
            crit = crit.apply_scope(scope)
            crit = crit.where(foreign_key => object)
            with_polymorphic_criterion(crit, base)
          end

          def execute_query(object, base)
            query_criteria(object, base).take
          end

          def with_polymorphic_criterion(criteria, base)
            if polymorphic?
              criteria.where(type => base.class.name)
            else
              criteria
            end
          end

          def query?(object)
            object && !object.is_a?(Mongoid::Document)
          end
        end
      end
    end
  end
end
