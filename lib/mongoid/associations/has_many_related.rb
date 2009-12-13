# encoding: utf-8
module Mongoid #:nodoc:
  module Associations #:nodoc:
    class HasManyRelated < DelegateClass(Array) #:nodoc:

      attr_reader :klass

      # Instantiate a new associated object and add it to the relationship.
      def build(attributes)
        object = @klass.instantiate(attributes.merge(@foreign_key => @parent.id))
        @documents << object
        object
      end

      # Create a new object for the association, save it, and add it.
      def create(attributes)
        object = build(attributes)
        object.save
      end

      # Initializing a related association only requires looking up the objects
      # by their ids.
      #
      # Options:
      #
      # document: The +Document+ that contains the relationship.
      # options: The association +Options+.
      def initialize(document, options)
        @parent, @klass = document, options.klass
        @foreign_key = document.class.to_s.foreign_key
        @documents = @klass.all(:conditions => { @foreign_key => document.id })
        super(@documents)
      end

      class << self
        # Preferred method for creating the new +HasManyRelated+ association.
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
        def update(related, document, options)
          name = document.class.to_s.underscore
          related.each { |child| child.send("#{name}=", document) }
        end
      end

    end
  end
end
