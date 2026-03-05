# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Persistable

    # Defines behavior for persistence operations that destroy documents.
    module Destroyable
      extend ActiveSupport::Concern

      # Remove the document from the database with callbacks.
      #
      # @example Destroy a document.
      #   document.destroy
      #
      # @param [ Hash ] options The options.
      # @option options [ true | false ] :persist Whether to persist
      #   the delete action. Callbacks will still be run even if false.
      # @option options [ true | false ] :suppress Whether to update
      #   the parent document in-memory when deleting an embedded document.
      #
      # @return [ true | false ] True if successful, false if not.
      def destroy(options = nil)
        raise Errors::ReadonlyDocument.new(self.class) if readonly?
        self.flagged_for_destroy = true
        result = run_callbacks(:commit, skip_if: -> { in_transaction? }) do
          run_callbacks(:destroy) do
            if catch(:abort) { apply_destroy_dependencies! }
              delete(options || {}).tap do |res|
                if res && in_transaction?
                  Threaded.add_modified_document(_session, self)
                end
              end
            else
              false
            end
          end
        end
        self.flagged_for_destroy = false
        result
      end

      # Remove the document from the database with callbacks. Raises
      # an error if the document is not destroyed.
      #
      # @example Destroy a document.
      #   document.destroy!
      #
      # @param [ Hash ] options The options.
      # @option options [ true | false ] :persist Whether to persist
      #   the delete action. Callbacks will still be run even if false.
      # @option options [ true | false ] :suppress Whether to update
      #   the parent document in-memory when deleting an embedded document.
      #
      # @raises [ Mongoid::Errors::DocumentNotDestroyed ] Raised if
      #   the document was not destroyed.
      #
      # @return [ true ] Always true.
      def destroy!(options = {})
        destroy(options) || raise(Errors::DocumentNotDestroyed.new(_id, self.class))
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
        def destroy_all(conditions = nil)
          where(conditions || {}).destroy
        end
      end
    end
  end
end
