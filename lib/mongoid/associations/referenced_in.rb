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
        @klass = options.klass

        if target
          replace(target)
        else
          foreign_key = document.send(options.foreign_key)
          replace(options.klass.find(foreign_key)) unless foreign_key.blank?
        end
        extends(options)
      end
      
      # Used for setting the association via a nested attributes setter on the
      # parent +Document+. Called when using accepts_nested_attributes_for.
      #
      # Options:
      #
      # attributes: The attributes for the new association
      #
      # Returns:
      #
      # A new target document.
      def nested_build(attributes, options = nil)
        options ||= {}
        _destroy = Boolean.set(attributes.delete('_destroy'))
        if options[:allow_destroy] && _destroy
          @target.destroy
          @target = nil
        elsif @target.present? || !options[:update_only]
          @target.attributes = @target.attributes.merge(attributes)
        end
        @target
      end
      
      # Builds a new Document and sets it as the association.
      #
      # Returns the newly created object.
      def build(attributes = {})
        target = @klass.instantiate(attributes)
        replace(target)
        target
      end
      
      # Builds a new Document and sets it as the association, then saves the
      # newly created document.
      #
      # Returns the newly created object.
      def create(attributes = {})
        build(attributes).tap(&:save)
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

        # Validate the options passed to the referenced in macro, to encapsulate
        # the behavior in this class instead of the associations module.
        #
        # Options:
        #
        # options: Thank you captain obvious.
        def validate_options(options = {})
          check_dependent_not_allowed!(options)
        end
      end
    end
  end
end
