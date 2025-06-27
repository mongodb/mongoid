# frozen_string_literal: true

module Mongoid
  module Errors
    # Raised when a polymorphic association is queried, but the type of the
    # association cannot be resolved. This usually happens when the data in
    # the database references a type that no longer exists.
    #
    # For example, consider the following model:
    #
    #   class Manager
    #     include Mongoid::Document
    #     belongs_to :unit, polymorphic: true
    #   end
    #
    # Imagine there is a document in the `managers` collection that looks
    # something like this:
    #
    #   { _id: ..., unit_id: ..., unit_type: 'Department::Engineering' }
    #
    # If, at some point in your refactoring, you rename the `Department::Engineering`
    # model to something else, Mongoid will no longer be able to resolve the
    # type of this association, and asking for `manager.unit` will raise this
    # exception.
    #
    # To fix this exception, you can add an alias to the model class so that it
    # can still be found, even after renaming it:
    #
    #   module Engineering
    #     class Department
    #       include Mongoid::Document
    #
    #       identify_as 'Department::Engineering'
    #
    #       # ...
    #     end
    #   end
    #
    # Better practice would be to use unique strings instead of class names to
    # identify these polymorphic types in the database (e.g. 'dept' instead of
    # 'Department::Engineering').
    class UnrecognizedModelAlias < MongoidError
      def initialize(model_alias)
        super(
          compose_message(
            'unrecognized_model_alias',
            model_alias: model_alias.inspect
          )
        )
      end
    end
  end
end
