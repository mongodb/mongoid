# encoding: utf-8
module Mongoid
  module Errors

    # This error is raised when calling #save! or .create! on a model when one
    # of the callbacks returns false.
    class Callback < MongoidError

      # Create the new callbacks error.
      #
      # @example Create the new callbacks error.
      #   Callbacks.new(Post, :create!)
      #
      # @param [ Class ] klass The class of the document.
      # @param [ Symbol ] method The name of the method.
      #
      # @since 2.2.0
      def initialize(klass, method)
        super(
          compose_message("callbacks", { klass: klass, method: method })
        )
      end
    end
  end
end
