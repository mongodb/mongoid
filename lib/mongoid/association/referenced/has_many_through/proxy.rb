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

          def_delegators :criteria,
                         :each, :to_a, :first, :last, :count, :size, :length,
                         :where, :pluck, :exists?, :any?, :none?, :empty?,
                         :limit, :skip, :order_by, :only, :without

          READONLY_METHODS = %i[
            << push concat substitute build new create create!
            delete delete_one delete_all destroy_all clear nullify
          ].freeze

          def initialize(base, association)
            @_base        = base
            @_association = association
          end

          # Lazily compute the resolved criteria when first needed.
          # Triggers the two-query through-join on first access.
          def criteria
            @criteria ||= @_association.resolve(@_base)
          end

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
