# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module SymbolQueryMacros

    # Adds macro behavior for adding symbol methods.
    module Macroable
      extend ActiveSupport::Concern

      class_methods do
        # Adds a method on Symbol for convenience in where queries for the
        # provided operators.
        #
        # @example Add a symbol key.
        #   key :all, '$all
        #
        # @param [ Symbol ] name The name of the method.
        # @param [ Symbol ] strategy The merge strategy.
        # @param [ String ] operator The MongoDB operator.
        # @param [ String ] additional The additional MongoDB operator.
        def key(name, strategy, operator, additional = nil, &block)
          ::Symbol.add_key(name, strategy, operator, additional, &block)
        end
      end

      included do
        key :eq, :override, '$eq'

        key :gt, :override, '$gt'

        key :gte, :override, '$gte'

        key :in, :intersect, '$in'

        key :lt, :override, '$lt'

        key :lte, :override, '$lte'

        key :mod, :override, '$mod'

        key :ne, :override, '$ne'

        key :nin, :intersect, '$nin'

        key :not, :override, '$not'

        key :with_size, :override, '$size' do |value|
          ::Integer.evolve(value)
        end

        key :with_type, :override, '$type' do |value|
          ::Integer.evolve(value)
        end

        key :asc, :override, 1

        key :ascending, :override, 1

        key :desc, :override, -1

        key :descending, :override, -1

        key :all, :union, '$all'

        key :elem_match, :override, '$elemMatch'

        key :exists, :override, '$exists' do |value|
          Mongoid::Boolean.evolve(value)
        end

        key :avg, :override, '$avg'

        key :max, :override, '$max'

        key :min, :override, '$min'

        key :sum, :override, '$sum'

        key :last, :override, '$last'

        key :push, :override, '$push'

        key :first, :override, '$first'

        key :add_to_set, :override, '$addToSet'

        key :intersects_line, :override, '$geoIntersects', '$geometry' do |value|
          { 'type' => LINE_STRING, 'coordinates' => value }
        end

        key :intersects_point, :override, '$geoIntersects', '$geometry' do |value|
          { 'type' => POINT, 'coordinates' => value }
        end

        key :intersects_polygon, :override, '$geoIntersects', '$geometry' do |value|
          { 'type' => POLYGON, 'coordinates' => value }
        end

        key :near, :override, '$near'

        key :near_sphere, :override, '$nearSphere'

        key :within_polygon, :override, '$geoWithin', '$geometry' do |value|
          { 'type' => POLYGON, 'coordinates' => value }
        end

        key :within_box, :override, '$geoWithin', '$box'
      end
    end
  end
end

::Mongoid::Criteria.include(Mongoid::SymbolQueryMacros::Macroable)
