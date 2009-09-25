module Mongoid #:nodoc:
  module Associations #:nodoc:
    class HasOneAssociation #:nodoc:

      attr_reader :document
      delegate :valid?, :to => :document

      # Creates the new association by finding the attributes in 
      # the parent document with its name, and instantiating a 
      # new document for it.
      #
      # All method calls on this object will then be delegated
      # to the internal document itself.
      def initialize(association_name, document)
        klass = association_name.to_s.titleize.constantize
        attributes = document.attributes[association_name]
        @document = klass.new(attributes)
        @document.parent = document
        decorate!
      end

      private
      def decorate!
        @document.public_methods(false).each do |method|
          (class << self; self; end).class_eval do
            define_method method do |*args|
              @document.send method, *args
            end
          end
        end
      end

    end
  end
end
