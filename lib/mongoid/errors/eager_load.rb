# encoding: utf-8
module Mongoid
  module Errors

    # This error is raised when attempting to eager load a many to many
    # relation.
    class EagerLoad < MongoidError

      # Create the new eager load error.
      #
      # @example Create the new eager load error.
      #   EagerLoad.new(:preferences)
      #
      # @param [ Symbol ] name The name of the relation.
      #
      # @since 2.2.0
      def initialize(name)
        super(compose_message("eager_load", { name: name }))
      end
    end
  end
end
