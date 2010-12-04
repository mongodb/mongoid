# encoding: utf-8
module Mongoid #:nodoc:
  module Modifiers #:nodoc:
    class AddToSet < Command #:nodoc:

      # Execute the persistence operation. This will add the supplied value to
      # the provided array field. If no field exists, it will be created and
      # set to the value provided.
      #
      # Options:
      #
      # field: The array field.
      # value: The value to add to the array.
      def persist(field, value)
        @document.collection.update(
          @document._selector,
          { "$addToSet" => { field => value } },
          :safe => safe_mode?(@options),
          :multi => false
        )
      end
    end
  end
end
