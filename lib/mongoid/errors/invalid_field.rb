# encoding: utf-8
module Mongoid
  module Errors

    # This error is raised when trying to create a field that conflicts with
    # an already defined method.
    class InvalidField < MongoidError

      # Create the new error.
      #
      # @example Create the error.
      #   InvalidField.new(person, :crazy_method_name)
      #
      # @param [ Class ] klass The document class.
      # @param [ Symbol ] name The method name.
      def initialize(klass, name)
        super(
          compose_message(
            "invalid_field",
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

      # Get the origin of the method.
      #
      # @example Get the originating class or module.
      #   error.origin(Person, :crazy_method_name)
      #
      # @param [ Class ] klass The document class.
      # @param [ Symbol ] name The method name.
      #
      # @return [ Class, Module ] The originating class or module.
      #
      # @since 3.0.0
      def origin(klass, name)
        klass.instance_method(name).owner
      end

      # Get the location of the method.
      #
      # @example Get the location of the method on the filesystem.
      #   error.location(Person, :crazy_method_name)
      #
      # @param [ Class ] klass The document class.
      # @param [ Symbol ] name The method name.
      #
      # @return [ Array<String, Integer> ] The location of the method.
      #
      # @since 3.0.0
      def location(klass, name)
        @location ||=
          (klass.instance_method(name).source_location || [ "Unknown", 0 ])
      end
    end
  end
end
