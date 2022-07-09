# frozen_string_literal: true

module Mongoid
  module Errors

    # Raised when an option provided for an association is invalid.
    class InvalidRelationOption < MongoidError

      # Create the new error.
      #
      # @example Create the new error.
      #   InvalidRelationOption.new(Person, invalid_option: 'make_me_a_sandwich')
      #
      # @param [ Class ] klass The model class.
      # @param [ String | Symbol ] name The association name.
      # @param [ Symbol ] option The invalid option.
      # @param [ Array<Symbol> ] valid_options The valid option.
      def initialize(klass, name, option, valid_options)
        super(
            compose_message(
                "invalid_relation_option",
                { klass: klass, name: name, option: option, valid_options: valid_options }
            )
        )
      end
    end
  end
end
