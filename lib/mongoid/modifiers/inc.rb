# encoding: utf-8
module Mongoid #:nodoc:
  module Modifiers #:nodoc:
    class Inc < Command #:nodoc:

      # Execute the persistence operation. This will increment the provided
      # field by the supplied value. If no field exists, it will be created and
      # set to the value provided.
      #
      # Options:
      #
      # field: The field to increment.
      # value: The number to increment by.
      def persist(field, value)
        @document.collection.update(
          @document._selector,
          { "$inc" => { field => value } },
          :safe => safe_mode?(@options),
          :multi => false
        )
      end
    end
  end
end
