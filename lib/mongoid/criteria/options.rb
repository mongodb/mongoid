# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  class Criteria

    # Module containing functionality for getting options on a Criteria object.
    #
    # @since 6.0.0
    module Options

      private

      def persistence_context
        klass.persistence_context
      end

      def set_persistence_context(options)
        PersistenceContext.set(klass, options)
      end

      def clear_persistence_context(original_cluster, original_context)
        PersistenceContext.clear(klass, original_cluster, original_context)
      end
    end
  end
end
