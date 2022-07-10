# frozen_string_literal: true

module Mongoid
  module Errors

    # This error is raised when trying to create an association that conflicts with
    # an already defined method.
    class InvalidRelation < MongoidError

      # Create the new error.
      #
      # @example Create the error.
      #   InvalidRelation.new(person, :crazy_relation_name)
      #
      # @param [ Class ] klass The document class.
      # @param [ Symbol ] name The method name.
      def initialize(klass, name)
        super(
            compose_message(
                "invalid_relation",
                {
                    name: name,
                    origin: origin(klass, name),
                    file: location(klass, name)[0],
                    line: location(klass, name)[1]
                }
            )
        )
      end

      private

      # Get the queryable of the method.
      #
      # @example Get the originating class or module.
      #   error.queryable(Person, :crazy_method_name)
      #
      # @param [ Class ] klass The document class.
      # @param [ Symbol ] name The method name.
      #
      # @return [ Class | Module ] The originating class or module.
      def origin(klass, name)
        klass.instance_method(name).owner
      end

      # Get the location of the association definition.
      #
      # @example Get the location of the method on the filesystem.
      #   error.location(Person, :crazy_method_name)
      #
      # @param [ Class ] klass The document class.
      # @param [ Symbol ] name The method name.
      #
      # @return [ Array<String, Integer> ] The location of the method.
      def location(klass, name)
        @location ||=
            (klass.instance_method(name).source_location || [ "Unknown", 0 ])
      end
    end
  end
end
