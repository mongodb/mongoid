# encoding: utf-8
module Mongoid
  module Persistable

    # Defines behaviour for persistence operations that save documents.
    #
    # @since 4.0.0
    module Savable

      # Save the document - will perform an insert if the document is new, and
      # update if not.
      #
      # @example Save the document.
      #   document.save
      #
      # @param [ Hash ] options Options to pass to the save.
      #
      # @return [ true, false ] True is success, false if not.
      #
      # @since 1.0.0
      def save(options = {})
        context = options[:mongo_context] || Context.new(self)
        if new_record?
          !insert(options.merge(mongo_context: context)).new_record?
        else
          update_document(options.merge(mongo_context: context))
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
      # @return [ true, false ] True if validation passed.
      #
      # @since 1.0.0
      def save!(options = {})
        context = options[:mongo_context] || Context.new(self)
        unless save(options.merge(mongo_context: context))
          fail_due_to_validation! unless errors.empty?
          fail_due_to_callback!(:save!)
        end
        true
      end
    end
  end
end
