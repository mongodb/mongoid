# encoding: utf-8
module Mongoid #:nodoc
  module Errors #:nodoc

    # This error is raised when trying to create a scope with an name already
    # taken by another scope or method
    #
    # @example Create the error.
    #   ScopeOverwrite.new(Person,'teenies')
    class ScopeOverwrite < MongoidError
      def initialize(model_name,scope_name)
        super(
          translate(
            "scope_overwrite",
            { :model_name => model_name, :scope_name => scope_name }
          )
        )
      end
    end
  end
end
