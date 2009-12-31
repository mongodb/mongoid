# encoding: utf-8
module Mongoid #:nodoc:
  module Associations #:nodoc:
    class BelongsTo #:nodoc:
      include Proxy

      attr_reader :document, :options

      # Creates the new association by setting the internal
      # document as the passed in Document. This should be the
      # parent.
      #
      # All method calls on this object will then be delegated
      # to the internal document itself.
      #
      # Options:
      #
      # document: The parent +Document+
      # options: The association options
      def initialize(document, options)
        @document, @options = document, options
      end

      # Returns the parent document. The id param is present for
      # compatibility with rails, however this could be overwritten
      # in the future.
      def find(id)
        @document
      end

      # Delegate all missing methods over to the parent +Document+.
      def method_missing(name, *args, &block)
        @document.send(name, *args, &block)
      end

      class << self
        # Creates the new association by setting the internal
        # document as the passed in Document. This should be the
        # parent.
        #
        # Options:
        #
        # document: The parent +Document+
        # options: The association options
        def instantiate(document, options)
          parent = document._parent
          parent.nil? ? nil : new(parent, options)
        end

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
