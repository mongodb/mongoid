module Mongoid #:nodoc:
  module Associations #:nodoc:
    class HasOne #:nodoc:
      include Decorator

      delegate :valid?, :to => :document

      attr_accessor :klass

      # Creates the new association by finding the attributes in 
      # the parent document with its name, and instantiating a 
      # new document for it.
      #
      # All method calls on this object will then be delegated
      # to the internal document itself.
      def initialize(document, options)
        @klass = options.klass
        attributes = document.attributes[options.name]
        @document = klass.instantiate(attributes || {})
        @document.parentize(document, options.name)
        decorate!
      end

      class << self
        # Perform an update of the relationship of the parent and child. This
        # is initialized by setting the has_one to the supplied child.
        def update(child, parent, options)
          unless child.respond_to?(:parentize)
            klass = options.klass
            child = klass.new(child)
          end
          child.parentize(parent, options.name)
          child.notify
          child
        end
      end

    end
  end
end
