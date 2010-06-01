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
      def initialize(document, foreign_key, options, target = nil)
        @options = options
        @target = target || options.klass.find(foreign_key)
        extends(options)
      end

      class << self
        # Instantiate a new +ReferencedIn+ or return nil if the foreign key is
        # nil. It is preferrable to use this method over the traditional call
        # to new.
        #
        # Options:
        #
        # document: The +Document+ that contains the relationship.
        # options: The association +Options+.
        def instantiate(document, options, target = nil)
          foreign_key = document.send(options.foreign_key)
          return nil if foreign_key.blank? && target.nil?
          new(document, foreign_key, options, target)
        end

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
          instantiate(document, options, target)
        end
      end
    end
  end
end
