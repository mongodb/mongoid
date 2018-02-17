# encoding: utf-8
module Mongoid
  module Association
    module Referenced
      class HasOne

        # The Builder behavior for has_one associations.
        #
        # @since 7.0
        module Buildable

          # This method either takes an _id or an object and queries for the
          # inverse side using the id or sets the object after clearing the
          # associated object.
          #
          # @return [ Document ] A single document.
          def build(base, object, type = nil)
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
            if object && (associated = object.send(inverse))
              associated.substitute(nil)
            end
          end

          def query_criteria(object, base)
            crit = klass.where(foreign_key => object)
            with_polymorphic_criterion(crit, base)
          end

          def execute_query(object, base)
            query_criteria(object, base).limit(-1).first(id_sort: :none)
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
