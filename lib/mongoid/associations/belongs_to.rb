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
      def initialize(name, document, options = {})
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
        # Perform an update of the relationship of the parent and child. This
        # is initialized by setting a parent object as the association on the
        # +Document+. Will properly set a has_one or a has_many.
        def update(parent, child, name, options = {})
          name = child.class.name.demodulize.downcase
          has_one = parent.associations[name]
          child.parentize(parent, name) if has_one
          child.parentize(parent, name.tableize) unless has_one
          child.notify
        end
      end
    end
  end
end
