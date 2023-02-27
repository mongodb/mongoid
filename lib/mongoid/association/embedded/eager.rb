# frozen_string_literal: true

module Mongoid
  module Association
    module Embedded

      # Eager class for has_many associations.
      class Eager < Association::Eager

        private

        def preload
          # Embedded associations have no preload phase
        end
      end

    end
  end
end
