# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Persistable

    # Defines behavior for persistence operations that upsert documents.
    module Upsertable

      # Perform an upsert of the document. If the document does not exist in the
      # database, then Mongo will insert a new one, otherwise the fields will get
      # overwritten with new values on the existing document.
      #
      # If the replace option is true, unspecified attributes will be dropped,
      # and if it is false, unspecified attributes will be maintained. The
      # replace option defaults to false in Mongoid 9.
      #
      # @example Upsert the document.
      #   document.upsert
      #
      # @example Upsert the document with replace.
      #   document.upsert(replace: true)
      #
      # @example Upsert with extra attributes to use when inserting.
      #   document.upsert(set_on_insert: { created_at: DateTime.now })
      #
      # @param [ Hash ] options The validation options.
      #
      # @option options [ true | false ] :validate Whether or not to validate.
      # @option options [ true | false ] :replace Whether or not to replace
      #   the document on upsert.
      # @option options [ Hash ] :set_on_insert The attributes to include if
      #   the document does not already exist.
      #
      # @return [ true ] True.
      def upsert(options = {})
        prepare_upsert(options) do
          if options[:replace]
            if options[:set_on_insert]
              raise ArgumentError, "cannot specify :set_on_insert with `replace: true`"
            end

            collection.find(atomic_selector).replace_one(
              as_attributes, upsert: true, session: _session)
          else
            attrs = { "$set" => as_attributes }
            attrs["$setOnInsert"] = options[:set_on_insert] if options[:set_on_insert]

            collection.find(atomic_selector).update_one(
              attrs, upsert: true, session: _session)
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
