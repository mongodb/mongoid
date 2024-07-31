# frozen_string_literal: true

module Mongoid
  module Errors
    # Raised when Mongoid tries to query the identifier to use for a given
    # class in a polymorphic association, but the class has not previously
    # been registered by resolver that was used for the query.
    #
    # Here's an exammple:
    #
    #   class Department
    #     include Mongoid::Document
    #     has_many :managers, as: :unit
    #   end
    #
    #   class Manager
    #     include Mongoid::Document
    #     belongs_to :unit, polymorphic: :org
    #   end
    #
    # The Manager class is configured to use a custom resolver named `:org`
    # when resolving the polymorphic `unit` association. However, the `Department`
    # class is not registered with that resolver. When the program tries to
    # associate a manager record with a department, it will not be able to find
    # the required key in the `:org` resolver, and will fail with this exception.
    #
    # The solution is to make sure the `Department` class is properly registered
    # with the `:org` resolver:
    #
    #   class Department
    #     include Mongoid::Document
    #     identify_as resolver: :org
    #     has_many :managers, as: :unit
    #   end
    class UnregisteredClass < MongoidError
      def initialize(klass, resolver)
        super(
          compose_message(
            'unregistered_class',
            klass: klass,
            resolver: resolver.inspect
          )
        )
      end
    end
  end
end
