# frozen_string_literal: true

module Mongoid
  module Errors

    # Default parent Mongoid error for all custom errors. This handles the base
    # key for the translations and provides the convenience method for
    # translating the messages.
    class MongoidError < StandardError
      include ErrorComposable
    end
  end
end
