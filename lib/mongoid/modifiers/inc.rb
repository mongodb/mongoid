# encoding: utf-8
module Mongoid #:nodoc:
  module Modifiers #:nodoc:
    class Inc #:nodoc:

      # Instantiate the new $inc modifier.
      #
      # Options:
      #
      # klass: The class to get the collection from.
      # options: The options to get passed through to the driver.
      def initialize(document, options = {})
        @document, @options = document, options
      end

      # Execute the persistence operation. This will increment the provided
      # field by the supplied value. If no field exists, it will be created and
      # set to the value provided.
      #
      # Options:
      #
      # field: The field to increment.
      # value: The number to increment by.
      def persist(field, value)
        safe = @options[:safe]
        @document.collection.update(
          @document._selector,
          { "$inc" => { field => value } },
          :safe => safe.nil? ? Mongoid.persist_in_safe_mode : safe,
          :multi => false
        )
      end
    end
  end
end
