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
      # @option options [ true | false ] :validate Whether or not to validate.
      # @option options [ true | false ] :replace Whether or not to replace the document on upsert.
      #
      # @return [ true ] True.
      def upsert(options = {})
        prepare_upsert(options) do
          if options[:replace]
            collection.find(atomic_selector).replace_one(
              as_attributes, upsert: true, session: _session)
          else
            collection.find(atomic_selector).update_one(
              { "$set" => as_attributes }, upsert: true, session: _session)
          end
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
      # @option options [ true | false ] :validate Whether or not to validate.
      #
      # @return [ true | false ] If the operation succeeded.
      def prepare_upsert(options = {})
        raise Errors::ReadonlyDocument.new(self.class) if readonly? && !Mongoid.legacy_readonly
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
