# encoding: utf-8
module Mongoid
  module Errors

    # This error is raised when trying to create a field that conflicts with
    # an already defined method.
    class InvalidEmbeddedFindAndModify < MongoidError

      # Create the new error.
      #
      # @example Create the error.
      #   InvalidFindAndModify.new(klass, criteria)
      #
      # @param [ Symbol ] name The findAndModify criteria.
      def initialize(criteria)
        "A sort on embedded documents cannot be used with findAndModify."
      end
    end
  end
end
