# encoding: utf-8
module Mongoid
  module Association
    module Referenced
      class HasOne

        module Buildable

          # This builder either takes an _id or an object and queries for the
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
            if associated = object.send(inverse)
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

          # Add polymorphic query criteria to a Criteria object, if this association is
          #  polymorphic.
          #
          # @params [ Mongoid::Criteria ] criteria The criteria object to add to.
          # @params [ Class ] object_class The object class.
          #
          # @return [ Mongoid::Criteria ] The criteria object.
          #
          # @since 7.0
          def with_polymorphic_criterion(criteria, base)
            if polymorphic?
              binding.pry
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
