# frozen_string_literal: true

module Mongoid
  class Criteria

    # Module containing functionality for getting options on a Criteria object.
    module Options

      def persistence_context
        PersistenceContext.get(self) || klass.persistence_context
      end

      def persistence_context?
        !!(PersistenceContext.get(self) || klass.persistence_context?)
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
