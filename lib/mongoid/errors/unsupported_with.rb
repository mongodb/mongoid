# frozen_string_literal: true

module Mongoid
  module Errors

    # Raised when #with is called on a document instance.
    class UnsupportedWith < MongoidError

      def initialize
        super(compose_message("unsupported_with"))
      end
    end
  end
end
