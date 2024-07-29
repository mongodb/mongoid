# frozen_string_literal: true
# rubocop:todo all

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
              # 1. get the resolver for the inverse association
              resolver = klass.reflect_on_association(as).resolver

              # 2. look up the list of keys from the resolver, given base.class
              keys = resolver.keys_for(base.class)

              # 3. use equality if there is just one key, `in` if there are multiple
              if keys.many?
                criteria.where(type => { :$in => keys })
              else
                criteria.where(type => keys.first)
              end
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
