# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Persistable

    # Defines behavior for persistence operations that destroy documents.
    #
    # @since 4.0.0
    module Destroyable
      extend ActiveSupport::Concern

      # Remove the document from the database with callbacks.
      #
      # @example Destroy a document.
      #   document.destroy
      #
      # @param [ Hash ] options Options to pass to destroy.
      #
      # @return [ true, false ] True if successful, false if not.
      #
      # @since 1.0.0
      def destroy(options = nil)
        raise Errors::ReadonlyDocument.new(self.class) if readonly?
        self.flagged_for_destroy = true
        result = run_callbacks(:destroy) do
          if catch(:abort) { apply_destroy_dependencies! }
            delete(options || {})
          else
            false
          end
        end
        self.flagged_for_destroy = false
        result
      end

      def destroy!(options = {})
        destroy || raise(Errors::DocumentNotDestroyed.new(_id, self.class))
      end

      module ClassMethods

        # Delete all documents given the supplied conditions. If no conditions
        # are passed, the entire collection will be dropped for performance
        # benefits. Fires the destroy callbacks if conditions were passed.
        #
        # @example Destroy matching documents from the collection.
        #   Person.destroy_all({ :title => "Sir" })
        #
        # @example Destroy all documents from the collection.
        #   Person.destroy_all
        #
        # @param [ Hash ] conditions Optional conditions to destroy by.
        #
        # @return [ Integer ] The number of documents destroyed.
        #
        # @since 1.0.0
        def destroy_all(conditions = nil)
          where(conditions || {}).destroy
        end
      end
    end
  end
end
