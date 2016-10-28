# encoding: utf-8
module Mongoid
  module Persistable

    # Defines behaviour for persistence operations that upsert documents.
    #
    # @since 4.0.0
    module Upsertable

      # Perform an upsert of the document. If the document does not exist in the
      # database, then Mongo will insert a new one, otherwise the fields will get
      # overwritten with new values on the existing document.
      #
      # @example Upsert the document.
      #   document.upsert
      #
      # @param [ Hash ] options The validation options.
      #
      # @return [ true ] True.
      #
      # @since 3.0.0
      def upsert(options = {})
        prepare_upsert(options) do
          collection.find(atomic_selector).update_one(as_document, upsert: true)
        end
      end

      private

      # Prepare the upsert for execution.
      #
      # @api private
      #
      # @example Prepare the upsert
      #   document.prepare_upsert do
      #     collection.find(selector).update(as_document)
      #   end
      #
      # @param [ Hash ] options The options hash.
      #
      # @return [ true, false ] If the operation succeeded.
      #
      # @since 4.0.0
      def prepare_upsert(options = {})
        return false if performing_validations?(options) && invalid?(:upsert)
        result = run_callbacks(:upsert) do
          yield(self)
          true
        end
        self.new_record = false
        post_process_persist(result, options) and result
      end
    end
  end
end
