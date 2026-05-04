# frozen_string_literal: true

module Mongoid
  module Association
    module Referenced
      class HasManyThrough
        include Relatable

        ASSOCIATION_OPTIONS = %i[class_name source through scope].freeze
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

        # Placeholder proxy class; replaced in a later task.
        class Proxy # rubocop:disable Lint/EmptyClass
        end
      end
    end
  end
end
