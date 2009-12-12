# encoding: utf-8
module Mongoid #:nodoc:
  module Associations #:nodoc:
    class HasOneRelated #:nodoc:

      delegate :==, :nil?, :to => :document
      attr_reader :document

      # Initializing a related association only requires looking up the objects
      # by their ids.
      #
      # Options:
      #
      # document: The +Document+ that contains the relationship.
      # options: The association +Options+.
      def initialize(document, options)
        name = document.class.to_s.foreign_key
        @document = options.klass.first(:conditions => { name => document.id })
      end

      # Delegate all missing methods over to the +Document+.
      def method_missing(name, *args)
        @document.send(name, *args)
      end

      class << self
        # Preferred method for creating the new +RelatesToMany+ association.
        #
        # Options:
        #
        # document: The +Document+ that contains the relationship.
        # options: The association +Options+.
        def instantiate(document, options)
          new(document, options)
        end

        # Returns the macro used to create the association.
        def macro
          :has_one_related
        end

        # Perform an update of the relationship of the parent and child. This
        # will assimilate the child +Document+ into the parent's object graph.
        #
        # Options:
        #
        # related: The related object to update.
        # document: The parent +Document+.
        # options: The association +Options+
        #
        # Example:
        #
        # <tt>HasManyToRelated.update(game, person, options)</tt>
        def update(related, document, options)
          name = document.class.to_s.underscore
          related.send("#{name}=", document)
          related
        end
      end

    end
  end
end
