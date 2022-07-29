# frozen_string_literal: true

module Mongoid
  module Persistable

    # Defines behavior for persistence operations that upsert documents.
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
      def upsert(options = {})
        prepare_upsert(options) do
          collection.find(atomic_selector).replace_one(
              as_attributes, upsert: true, session: _session)
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
      # @return [ true | false ] If the operation succeeded.
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
