# frozen_string_literal: true

module Mongoid
  module Errors

    # This error is raised in case of an association type mismatch. This is
    # triggered when assigning a document of the wrong type to an association.
    class AssociationTypeMismatch < MongoidError

      # @param [ Class ] klass The (mismatched) klass of the assigned document.
      # @param [ Class ] assoc_klass The association klass.
      # @param [ Symbol ] name The association name.
      def initialize(klass, assoc_klass, name)
        super(
          compose_message(
            "association_type_mismatch",
            {
              klass: klass,
              assoc_klass: assoc_klass,
              name: name.inspect,
            }
          )
        )
      end
    end
  end
end
