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
      # @return [ true | false ] True is success, false if not.
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
