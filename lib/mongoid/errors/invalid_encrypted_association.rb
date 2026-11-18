# frozen_string_literal: true

module Mongoid
  module Errors
    # This error is raised when an encrypted field is used as the foreign key
    # of a has_and_belongs_to_many association. Encryption protects an array
    # only as a whole, while the association queries and atomically updates
    # individual elements of it, so the association cannot manage the key.
    class InvalidEncryptedAssociation < MongoidError
      # Create the new error.
      #
      # @example Create the error.
      #   InvalidEncryptedAssociation.new(Person, :preferences, 'preference_ids')
      #
      # @param [ Class ] klass The model declaring the association.
      # @param [ Symbol | String ] association The association name.
      # @param [ String ] field The encrypted foreign key field.
      def initialize(klass, association, field)
        super(
          compose_message(
            'invalid_encrypted_association',
            { klass: klass.name, association: association, field: field }
          )
        )
      end
    end
  end
end
