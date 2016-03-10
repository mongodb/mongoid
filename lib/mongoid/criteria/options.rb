# encoding: utf-8
module Mongoid
  class Criteria
    module Options

      private

      def persistence_context
        klass.persistence_context
      end

      def set_persistence_context(options)
        PersistenceContext.set(klass, options)
      end

      def clear_persistence_context(original_cluster)
        PersistenceContext.clear(klass, original_cluster)
      end
    end
  end
end
