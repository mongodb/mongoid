# encoding: utf-8
module Mongoid
  module Association
    module Referenced
      class HasOne

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
            unless base.new_record?
              execute_query(object, base)
            end
          end

          private

          def execute_query(object, base)
            crit = klass.where(foreign_key => object)
            crit = add_polymorphic_criterion(crit, base)
            crit.limit(-1).first(id_sort: :none)
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
          def add_polymorphic_criterion(criteria, base)
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
