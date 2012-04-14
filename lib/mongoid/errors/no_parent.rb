# encoding: utf-8
module Mongoid
  module Errors

    # This error is raised when trying to persist an embedded document
    # when there is no parent set.
    class NoParent < MongoidError

      # Create the new error.
      #
      # @example Create the new error.
      #   NoParent.new(klass)
      #
      # @param [ Class ] klass The class of the embedded document.
      #
      # @since 3.0.0
      def initialize(klass)
        super(
          compose_message("no_parent", { klass: klass })
        )
      end
    end
  end
end
