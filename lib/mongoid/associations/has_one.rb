module Mongoid #:nodoc:
  module Associations #:nodoc:
    class HasOne #:nodoc:
      include Decorator

      delegate :valid?, :to => :document

      # Creates the new association by finding the attributes in 
      # the parent document with its name, and instantiating a 
      # new document for it.
      #
      # All method calls on this object will then be delegated
      # to the internal document itself.
      def initialize(name, document, options = {})
        class_name = options[:class_name]
        klass = class_name ? class_name.constantize : name.to_s.camelize.constantize
        attributes = document.attributes[name]
        @document = klass.instantiate(attributes || {})
        @document.parentize(document, name)
        decorate!
      end

      class << self
        # Perform an update of the relationship of the parent and child. This
        # is initialized by setting the has_one to the supplied child.
        def update(child, parent, name, options = {})
          unless child.respond_to?(:parentize)
            class_name = options[:class_name]
            klass = class_name ? class_name.constantize : name.to_s.camelize.constantize
            child = klass.new(child)
          end
          child.parentize(parent, name)
          child.notify
          child
        end
      end

    end
  end
end
