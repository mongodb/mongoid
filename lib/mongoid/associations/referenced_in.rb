# encoding: utf-8
module Mongoid #:nodoc:
  module Associations #:nodoc:
    # Represents a relational association to a "parent" object.
    class ReferencedIn < Proxy

      # Initializing a related association only requires looking up the object
      # by its id.
      #
      # Options:
      #
      # document: The +Document+ that contains the relationship.
      # options: The association +Options+.
      def initialize(document, options, target = nil)
        @options = options

        if target
          replace(target)
        else
          foreign_key = document.send(options.foreign_key)
          replace(options.klass.find(foreign_key)) unless foreign_key.blank?
        end

        extends(options)
      end

      # Replaces the target with a new object
      #
      # Returns the association proxy
      def replace(obj)
        @target = obj
        self
      end

      class << self
        # Returns the macro used to create the association.
        def macro
          :referenced_in
        end

        # Perform an update of the relationship of the parent and child. This
        # will assimilate the child +Document+ into the parent's object graph.
        #
        # Options:
        #
        # target: The target(parent) object
        # document: The +Document+ to update.
        # options: The association +Options+
        #
        # Example:
        #
        # <tt>ReferencedIn.update(person, game, options)</tt>
        def update(target, document, options)
          document.send("#{options.foreign_key}=", target ? target.id : nil)
          new(document, options, target)
        end
      end
    end
  end
end
