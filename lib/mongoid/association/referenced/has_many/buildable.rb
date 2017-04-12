# encoding: utf-8
module Mongoid
  module Association
    module Referenced
      class HasMany

        module Buildable

          # This builder either takes an _id or an object and queries for the
          # inverse side using the id or sets the object.
          #
          # @example Build the document.
          #   Builder.new(meta, attrs).build
          #
          # @param [ String ] type The type of document to query for.
          #
          # @return [ Document ] A single document.
          def build(base, object, type = nil)
            return object unless query?(object)
            return [] if object.is_a?(Array)
            query_criteria(object, base)
          end

          private

          def query_criteria(object, base)
            crit = klass.where(foreign_key => object)
            crit = with_polymorphic_criterion(crit, base)
            crit = with_ordering(crit)
            with_inverse_field_criterion(crit)
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
              criteria.where(type => base.class.name)
            else
              criteria
            end
          end

          def with_ordering(criteria)
            if order
              criteria.order_by(order)
            else
              criteria
            end
          end

          def with_inverse_field_criterion(criteria)
            inverse_association = inverse_association(klass)
            if inverse_association.try(:inverse_of)
              criteria.any_in(inverse_association.inverse_of => [name, nil])
            else
              criteria
            end
          end

          def query?(object)
            object && Array(object).all? { |d| !d.is_a?(Mongoid::Document) }
          end
        end
      end
    end
  end
end
