# encoding: utf-8
module Mongoid
  module Errors

    # This error is raised when trying to create a field that has an invalid
    # option.
    class InvalidFieldOption < MongoidError

      # Create the new error.
      #
      # @example Create the error.
      #   InvalidFieldOption.new(Model, :name, :localized, [ :localize ])
      #
      # @param [ Class ] klass The document class.
      # @param [ Symbol ] name The method name.
      # @param [ Symbol ] option The option name.
      # @param [ Array<Symbol> ] valid All the valid options.
      #
      # @since 3.0.0
      def initialize(klass, name, option, valid)
        super(
          compose_message(
            "invalid_field_option",
            {
              name: name,
              klass: klass,
              option: option,
              valid: valid.join(", ")
            }
          )
        )
      end
    end
  end
end
