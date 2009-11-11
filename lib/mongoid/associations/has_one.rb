module Mongoid #:nodoc:
  module Associations #:nodoc:
    class HasOne #:nodoc:
      include Decorator

      delegate :valid?, :to => :document

      # Builds a new Document and sets up the has one association.
      #
      # Returns the newly created object.
      def build(attributes = nil)
        attributes ||= {}
        @document = @klass.new(attributes)
        @document.parentize(@parent, @association_name)
        @document
      end

      # Creates the new association by finding the attributes in 
      # the parent document with its name, and instantiating a 
      # new document for it.
      #
      # All method calls on this object will then be delegated
      # to the internal document itself.
      def initialize(name, document, options = {})
        @parent = document
        class_name = options[:class_name]
        @klass = class_name ? class_name.constantize : name.to_s.camelize.constantize
        attributes = document.attributes[name]
        @document = @klass.new(attributes)
        @document.parentize(document, name)
        decorate!
      end

      # Return the target of the proxy
      def target
        @document
      end

      class << self
        # Perform an update of the relationship of the parent and child. This
        # is initialized by setting the has_one to the supplied child.
        def update(child, parent, name, options = {})
          child.parentize(parent, name)
          child.notify
          new(name, parent, options)
        end
      end

    end
  end
end
