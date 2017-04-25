# encoding: utf-8
module Mongoid
  module Errors

    # This error is raised when trying to persist an inherited document with
    # non-existed subclass type.
    #
    # @example Create the error.
    #   InvalidSubclassType.new(Person, "Dog")
    class InvalidSubclassType < MongoidError
      def initialize(klass, type)
        super(
          compose_message("invalid_subclass_type", { klass: klass.name, type: type })
        )
      end
    end
  end
end
