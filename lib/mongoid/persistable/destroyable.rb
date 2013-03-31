# encoding: utf-8
module Mongoid
  module Persistable

    # Defines behaviour for persistence operations that destroy documents.
    #
    # @since 2.0.0
    module Destroyable

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
      def destroy(options = {})
        self.flagged_for_destroy = true
        result = run_callbacks(:destroy) { delete(options) }
        self.flagged_for_destroy = false
        result
      end
    end
  end
end
