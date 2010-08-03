# encoding: utf-8
module Mongoid #:nodoc:
  module Associations #:nodoc:
    # Represents an relational one-to-one association with an object in a
    # separate collection or database.
    class ReferencesOne < Proxy

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
        inverse = @target.associations.values.detect do |metadata|
          metadata.options.klass == @parent.class
        end
        name = inverse.name
        @target.send("#{name}=", @parent)

        self
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
        @foreign_key = options.foreign_key
        @target = @klass.first(:conditions => { @foreign_key => @parent.id })
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
          build(attributes)
        end
        @target
      end

      class << self
        # Returns the macro used to create the association.
        def macro
          :references_one
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
        # <tt>HasOneToRelated.update(game, person, options)</tt>
        def update(target, document, options)
          if target
            name = document.class.to_s.underscore
            proxy = new(document, options)
            proxy.replace(target)
          end
          proxy
        end
      end
    end
  end
end
