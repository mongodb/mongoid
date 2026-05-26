# frozen_string_literal: true

module Mongoid
  module Association
    module Referenced
      class HasManyThrough
        # Read-only proxy for has_many :through associations. Wraps the lazy
        # Criteria returned by the association and raises ReadonlyAssociation on
        # any write attempt.
        class Proxy
          extend Forwardable
          include Enumerable

          module ClassMethods
            def eager_loader(association, docs)
              Eager.new(association, docs)
            end

            def embedded?
              false
            end
          end

          extend ClassMethods

          # Enumerable methods use the preloaded array when available; query
          # methods always delegate to criteria so callers get a Criteria back.
          def_delegators :_source,
                         :each, :to_a, :first, :last, :count, :size, :length,
                         :exists?, :any?, :none?, :empty?

          def_delegators :criteria,
                         :where, :pluck, :limit, :skip, :order_by, :only, :without,
                         :sum, :avg, :min, :max

          READONLY_METHODS = %i[
            << push concat substitute build new create create!
            delete delete_one delete_all destroy_all clear nullify
          ].freeze

          def initialize(base, association, preloaded: nil)
            @_base        = base
            @_association = association
            @preloaded    = preloaded
          end

          def criteria
            @criteria ||= @_association.criteria(@_base)
          end

          private

          def _source
            @preloaded || criteria
          end

          public

          READONLY_METHODS.each do |meth|
            define_method(meth) do |*|
              raise Mongoid::Errors::ReadonlyAssociation.new(@_base.class, @_association)
            end
          end
        end
      end
    end
  end
end
