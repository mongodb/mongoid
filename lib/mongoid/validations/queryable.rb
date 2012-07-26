# encoding: utf-8
module Mongoid
  module Validations
    module Queryable

      # Wrap the validation inside the an execution block that alert's the
      # session not to clear it's persistence options.
      #
      # @example Execute the validation with a query.
      #   with_query(document) do
      #     #...
      #   end
      #
      # @param [ Document ] document The document being validated.
      #
      # @return [ Object ] The result of the yield.
      #
      # @since 3.0.2
      def with_query(document)
        begin
          Threaded.begin("#{klass.name}-validate-with-query")
          yield
        ensure
          klass.clear_persistence_options unless document.errors.empty?
          Threaded.exit("#{klass.name}-validate-with-query")
        end
      end
    end
  end
end
