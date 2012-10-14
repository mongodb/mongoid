# encoding: utf-8
module Mongoid
  module Errors

    # This error is raised when trying to set an attribute with an invalid value.
    # For example when try to set an Array value to a Hash attribute.
    #
    class InvalidValue < MongoidError
      def initialize(field_class, value_class)
        super(
          compose_message("invalid_value", { value_class: value_class, field_class: field_class  })
        )
      end
    end
  end
end
