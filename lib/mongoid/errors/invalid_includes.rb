# encoding: utf-8
module Mongoid
  module Errors

    # This error is raised when an invalid value is passed to an eager
    # loading query.
    class InvalidIncludes < MongoidError

      # Initialize the error.
      #
      # @example Initialize the error.
      #   InvalidIncludes.new(Band, [ :members ])
      #
      # @param [ Class ] klass The model class.
      # @param [ Array<Object> ] args The arguments passed to the includes.
      #
      # @since 3.0.2
      def initialize(klass, args)
        super(
          compose_message(
            "invalid_includes",
            {
              klass: klass.name,
              args: args.map(&:inspect).join(", "),
              relations: klass.relations.keys.map(&:inspect).join(", ")
            }
          )
        )
      end
    end
  end
end
