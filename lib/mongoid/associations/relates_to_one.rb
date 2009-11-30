module Mongoid #:nodoc:
  module Associations #:nodoc:
    class RelatesToOne #:nodoc:
      include Decorator

      # Initializing a related association only requires looking up the object
      # by its id.
      #
      # Options:
      #
      # document: The +Document+ that contains the relationship.
      # options: The association +Options+.
      def initialize(document, options)
        @document = options.klass.find(document.send(options.foreign_key))
        decorate!
      end

      class << self
        # Returns the macro used to create the association.
        def macro
          :relates_to_one
        end

        # Perform an update of the relationship of the parent and child. This
        # will assimilate the child +Document+ into the parent's object graph.
        #
        # Options:
        #
        # related: The related object
        # parent: The parent +Document+ to update.
        # options: The association +Options+
        #
        # Example:
        #
        # <tt>RelatesToOne.update(game, person, options)</tt>
        def update(related, parent, options)
          parent.send("#{options.foreign_key}=", related.id)
        end
      end

    end
  end
end
