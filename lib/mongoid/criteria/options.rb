# frozen_string_literal: true

module Mongoid
  class Criteria

    # Module containing functionality for getting options on a Criteria object.
    module Options

      # Returns the current persistence context or a new one constructed with
      # self.
      #
      # @return [ Mongoid::PersistenceContext ] the persistence context.
      def persistence_context
        PersistenceContext.get(self) || klass.persistence_context
      end

      # Was a persistence context set?
      #
      # @return [ true | false ] true if a persistence context was set,
      #   false otherwise.
      def persistence_context?
        !!(PersistenceContext.get(self) || klass.persistence_context?)
      end

      # Clears the persistence context on the called object.
      def clear_persistence_context!
        clear_persistence_context(@original_cluster, @original_context)
      end

      private

      def set_persistence_context(options)
        PersistenceContext.set(self, options)
      end

      def clear_persistence_context(original_cluster, original_context)
        PersistenceContext.clear(self, original_cluster, original_context)
      end
    end
  end
end
