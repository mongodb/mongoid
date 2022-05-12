# frozen_string_literal: true

module Mongoid
  module Errors

    # This error is raised when trying to use the setter for a field that starts
    # with a dollar sign ($) or contains a dot/period (.).
    class ProhibitedSetter < MongoidError

      # Create the new error.
      #
      # @param [ Class ] klass The class of the document.
      # @param [ Class ] meth The method attempted to be called.
      def initialize(klass, meth)
        super(
          compose_message("prohibited_setter", { klass: klass, meth: meth })
        )
      end
    end
  end
end
