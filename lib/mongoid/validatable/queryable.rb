# frozen_string_literal: true

module Mongoid
  module Validatable
    module Queryable

      # Wrap the validation inside the an execution block that alert's the
      # client not to clear its persistence options.
      #
      # @example Execute the validation with a query.
      #   with_query(document) do
      #     #...
      #   end
      #
      # @param [ Document ] document The document being validated.
      #
      # @return [ Object ] The result of the yield.
      def with_query(document)
        klass = document.class
        begin
          Threaded.begin_execution("#{klass.name}-validate-with-query")
          yield
        ensure
          Threaded.exit_execution("#{klass.name}-validate-with-query")
        end
      end
    end
  end
end
