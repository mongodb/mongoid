# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # Raised when Javascript criteria selector is passed for embedded document.
    class UnsupportedJavascriptSelector < MongoidError

      # Create the new error caused by using Javascript in embedded document criteria selector.
      #
      # @example Create the error.
      #   UnsupportedJavascriptSelector.new
      #
      def initialize(embedded)
        super(
          compose_message(
            "unsupported_javascript_criteria",
            { embedded: embedded.name }
          )
        )
      end
    end
  end
end
