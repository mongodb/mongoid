# frozen_string_literal: true

module Mongoid
  module Errors
    # Raised when attempting to write to a :through association, which is
    # read-only.
    class ReadonlyAssociation < MongoidError
      # Instantiate the exception.
      #
      # @example Create the error.
      #   ReadonlyAssociation.new(Physician, association)
      #
      # @param [ Class ] klass The owner class.
      # @param [ Mongoid::Association::Relatable ] association The through association.
      def initialize(klass, association)
        super(
          compose_message(
            'readonly_association',
            {
              klass: klass,
              name: association.name,
              through: association.options[:through]
            }
          )
        )
      end
    end
  end
end
