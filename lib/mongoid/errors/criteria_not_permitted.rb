# encoding: utf-8
module Mongoid
  module Errors

    # This error is raised when calling #where on a model with untrusted
    # user input.
    class CriteriaNotPermitted < MongoidError

      # Create a new error.
      #
      # @param [ Class ] klass The class of the document.
      # @param [ String ] method The method called without permission
      # @param [ Hash ] method The criteria
      #
      # @since 4.0.0
      def initialize(klass, method, criteria)
        super(
          compose_message(
            "criteria_not_permitted",
            { klass: klass, method: method, criteria: criteria }
          )
        )
      end
    end
  end
end

