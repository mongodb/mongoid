# encoding: utf-8
module Mongoid
  module Errors

    # Raised when a persistence method ending in ! fails validation. The message
    # will contain the full error messages from the +Document+ in question.
    #
    # @example Create the error.
    #   Validations.new(person.errors)
    class Validations < MongoidError
      attr_reader :document
      alias :record :document

      def initialize(document)
        @document = document

        super(
          compose_message(
            "validations",
            {
              document: document.class,
              errors: document.errors.full_messages.join(", ")
            }
          )
        )
      end
    end
  end
end
