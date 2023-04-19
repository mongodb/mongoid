# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Association
    module Embedded

      # Eager class for embedded associations (embedded_in, embeds_many,
      # embeds_one).
      class Eager < Association::Eager

        private

        # Embedded associations have no preload phase, since the embedded
        # documents are loaded with the parent document. This method is
        # implemented as a no-op to represent that.
        def preload
        end
      end

    end
  end
end
