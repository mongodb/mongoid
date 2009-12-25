# encoding: utf-8
module Mongoid #:nodoc:
  module Associations #:nodoc:
    class BelongsToRelated #:nodoc:
      include Proxy

      attr_reader :document, :options

      # Initializing a related association only requires looking up the object
      # by its id.
      #
      # Options:
      #
      # document: The +Document+ that contains the relationship.
      # options: The association +Options+.
      def initialize(document, foreign_key, options)
        @document = options.klass.find(foreign_key)
      end

      # Delegate all missing methods over to the +Document+.
      def method_missing(name, *args)
        @document.send(name, *args)
      end

      class << self
        # Instantiate a new +BelongsToRelated+ or return nil if the foreign key is
        # nil. It is preferrable to use this method over the traditional call
        # to new.
        #
        # Options:
        #
        # document: The +Document+ that contains the relationship.
        # options: The association +Options+.
        def instantiate(document, options)
          foreign_key = document.send(options.foreign_key)
          foreign_key.blank? ? nil : new(document, foreign_key, options)
        end

        # Returns the macro used to create the association.
        def macro
          :belongs_to_related
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
        # <tt>BelongsToRelated.update(game, person, options)</tt>
        def update(related, parent, options)
          parent.send("#{options.foreign_key}=", related.id) if related
          related
        end
      end

    end
  end
end
