# frozen_string_literal: true

module Mongoid
  module Persistable

    # Defines behavior for persistence operations that save documents.
    module Savable

      # Save the document - will perform an insert if the document is new, and
      # update if not.
      #
      # @example Save the document.
      #   document.save
      #
      # @param [ Hash ] options Options to pass to the save.
      #
      # @option options [ true | false ] :touch Whether or not the updated_at
      #   attribute will be updated with the current time. When this option is
      #   false, none of the embedded documents will be touched. This option is
      #   ignored when saving a new document, and the created_at and updated_at
      #   will be set to the current time.
      #
      # @return [ true | false ] True if success, false if not.
      def save(options = {})
        if new_record?
          !insert(options).new_record?
        else
          update_document(options)
        end
      end

      # Save the document - will perform an insert if the document is new, and
      # update if not. If a validation error occurs an error will get raised.
      #
      # @example Save the document.
      #   document.save!
      #
      # @param [ Hash ] options Options to pass to the save.
      #
      # @option options [ true | false ] :touch Whether or not the updated_at
      #   attribute will be updated with the current time. When this option is
      #   false, none of the embedded documents will be touched.This option is
      #   ignored when saving a new document, and the created_at and updated_at
      #   will be set to the current time.
      #
      # @raise [ Errors::Validations ] If validation failed.
      # @raise [ Errors::Callback ] If a callback returns false.
      #
      # @return [ true | false ] True if validation passed.
      def save!(options = {})
        unless save(options)
          fail_due_to_validation! unless errors.empty?
          fail_due_to_callback!(:save!)
        end
        true
      end
    end
  end
end
