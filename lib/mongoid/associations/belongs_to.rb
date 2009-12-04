# encoding: utf-8
module Mongoid #:nodoc:
  module Associations #:nodoc:
    class BelongsTo #:nodoc:
      include Decorator

      # Creates the new association by setting the internal 
      # document as the passed in Document. This should be the
      # parent.
      #
      # All method calls on this object will then be delegated
      # to the internal document itself.
      def initialize(document, options)
        @document = document.parent
        decorate!
      end

      # Returns the parent document. The id param is present for
      # compatibility with rails, however this could be overwritten 
      # in the future.
      def find(id)
        @document
      end

      class << self
        # Returns the macro used to create the association.
        def macro
          :belongs_to
        end

        # Perform an update of the relationship of the parent and child. This
        # is initialized by setting a parent object as the association on the
        # +Document+. Will properly set a has_one or a has_many.
        def update(parent, child, options)
          child.parentize(parent, options.inverse_of)
          child.notify
          parent
        end
      end
    end
  end
end
