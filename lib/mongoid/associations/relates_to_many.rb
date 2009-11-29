module Mongoid #:nodoc:
  module Associations #:nodoc:
    class RelatesToMany < DelegateClass(Array) #:nodoc:

      # Initializing a related association only requires looking up the objects
      # by their ids.
      #
      # Options:
      #
      # document: The +Document+ that contains the relationship.
      # options: The association +Options+.
      def initialize(document, options)
        @documents = options.klass.criteria.in(:_id => document.send("#{options.name}_ids"))
        super(@documents)
      end

      class << self
        # Returns the macro used to create the association.
        def macro
          :relates_to_many
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
          parent.send("#{options.name}_ids=", related.collect(&:id))
        end
      end

    end
  end
end
