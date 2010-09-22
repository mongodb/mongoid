# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # Raised when a persisence method ending in ! fails validation. The message
    # will contain the full error messages from the +Document+ in question.
    #
    # Example:
    #
    # <tt>Validations.new(person.errors)</tt>
    class Validations < MongoidError
      attr_reader :document
      def initialize(document)
        @document = document
        super(
          translate(
            "validations",
            { :errors => document.errors.full_messages.join(", ") }
          )
        )
      end
    end
  end
end
