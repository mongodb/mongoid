module Mongoid #:nodoc:
  module Associations #:nodoc:
    class BelongsToAssociation #:nodoc:

      # Creates the new association by setting the internal 
      # document as the passed in Document. This should be the
      # parent.
      #
      # All method calls on this object will then be delegated
      # to the internal document itself.
      def initialize(document)
        @document = document.parent
      end

      # All calls to this association will be delegated straight
      # to the encapsulated document.
      def method_missing(method, *args)
        @document.send(method, *args)
      end

    end
  end
end
