# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Errors

    # This error is raised when trying to set or get the 
    # discriminator key on a child class.
    class InvalidDiscriminatorKeyTarget < MongoidError
      def initialize(class_name, superclass)
        super(
          compose_message(
            "invalid_discriminator_key_target",
            { class_name: class_name,  superclass: superclass}
          )
        )
      end
    end
  end
end
