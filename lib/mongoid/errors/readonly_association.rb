# frozen_string_literal: true

module Mongoid
  module Errors
    # Raised when attempting to write to a :through association, which is
    # read-only.
    class ReadonlyAssociation < MongoidError
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
