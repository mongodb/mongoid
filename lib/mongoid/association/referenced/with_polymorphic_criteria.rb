# frozen_string_literal: true

module Mongoid
  module Association
    module Referenced
      # Implements the `with_polymorphic_criteria` shared behavior.
      #
      # @api private
      module WithPolymorphicCriteria
        # If the receiver represents a polymorphic association, applies
        # the polymorphic search criteria to the given `criteria` object.
        #
        # @param [ Mongoid::Criteria ] criteria the criteria to append to
        #   if receiver is polymorphic.
        # @param [ Mongoid::Document ] base the document to use when resolving
        #   the polymorphic type keys.
        #
        # @return [ Mongoid::Criteria] the resulting criteria, which may be
        #   the same as the input.
        def with_polymorphic_criterion(criteria, base)
          if polymorphic?
            # 1. get the resolver for the inverse association
            resolver = klass.reflect_on_association(as).resolver

            # 2. look up the list of keys from the resolver, given base
            keys = resolver.keys_for(base)

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
      end
    end
  end
end
