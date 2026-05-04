# frozen_string_literal: true

module Mongoid
  module Association
    module Referenced
      class HasOneThrough
        include Relatable

        ASSOCIATION_OPTIONS = %i[source through scope].freeze
        VALID_OPTIONS = (ASSOCIATION_OPTIONS + SHARED_OPTIONS).freeze

        def embedded?
          false
        end

        def setup!
          self
        end

        def relation
          Proxy
        end

        def validation_default
          false
        end

        # Placeholder proxy class; replaced in a later task.
        class Proxy # rubocop:disable Lint/EmptyClass
        end
      end
    end
  end
end
