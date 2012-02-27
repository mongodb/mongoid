# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # This error is raised when attempting to version an embedded document.
    class VersioningNotOnRoot < MongoidError

      # Create the new error.
      #
      # @example Create the new error.
      #   VersioningNotOnRoot.new(Address)
      #
      # @param [ Class ] klass The embedded class.
      #
      # @since 3.0.0
      def initialize(klass)
        super(
          compose_message("versioning_not_on_root", { :klass => klass })
        )
      end
    end
  end
end
