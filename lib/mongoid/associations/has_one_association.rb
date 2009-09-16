module Mongoid
  module Associations
    class HasOneAssociation

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
      end

      # All calls to this association will be delegated straight
      # to the encapsulated document.
      def method_missing(method, *args)
        @document.send(method, *args)
      end

    end
  end
end
