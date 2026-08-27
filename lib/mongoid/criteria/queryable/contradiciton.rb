# frozen_string_literal: true

module Mongoid
  class Criteria
    module Queryable
      # Checks whether the criteria contains a contradiction which
      # would cause the query to return no results. This can result from:
      # - Conflicting equals: { 'name' => 'Bob', 'name' => 'Joe' }
      # - Empty $in: { '$in' => [] }
      # - Not empty $nin: { '$not' => { '$nin' => [] } }
      module Contradiction
        extend self

        def contradicted?(criteria)
          traverse_selector(criteria.selector)
        end

        private

        def traverse_selector(selector, negated = false)
          # return true if selector.any? { |k, v| empty_condition?(k, v, '$in') }

          # selector.all?
          selector.each do |k, v|
            return true if empty_condition?(k, v, '$in')

            case k.to_s
            when '$and'
              Array(v).any? { |s| traverse_selector(s, negated) }
            when '$or'
              Array(v).all? { |s| traverse_selector(s, negated) }
            when '$nor'
              Array(v).all? { |s| traverse_selector(s, !negated) }
            when '$not'
              traverse_selector(selector, !negated)
            end
          end
        end

        def empty_condition?(key, value, operator)
          !key.to_s.start_with?('$') &&
            value.is_a?(Hash) &&
            value.size == 1 &&
            (value[operator] || value[operator.to_sym]) == []
        end
      end
    end
  end
end
