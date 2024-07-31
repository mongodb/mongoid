# frozen_string_literal: true

module Mongoid
  module Errors
    # Raised when a model resolver is referenced, but not registered.
    #
    #   class Manager
    #     include Mongoid::Document
    #     belongs_to :unit, polymorphic: :org
    #   end
    #
    # If `:org` has not previously been registered as a model resolver,
    # Mongoid will raise UnrecognizedResolver when it tries to resolve
    # a manager's unit.
    class UnrecognizedResolver < MongoidError
      def initialize(resolver)
        super(
          compose_message(
            'unrecognized_resolver',
            resolver: resolver.inspect,
            resolvers: [ :default, *Mongoid::ModelResolver.resolvers.keys ].inspect
          )
        )
      end
    end
  end
end
