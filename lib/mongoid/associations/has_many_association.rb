module Mongoid #:nodoc:
  module Associations #:nodoc:
    class HasManyAssociation < DelegateClass(Array) #:nodoc:

      # Creates the new association by finding the attributes in 
      # the parent document with its name, and instantiating a 
      # new document for each one found. These will then be put in an 
      # internal array.
      #
      # This then delegated all methods to the array class since this is 
      # essentially a proxy to an array itself.
      def initialize(association_name, document)
        klass = association_name.to_s.classify.constantize
        attributes = document.attributes[association_name]
        @documents = attributes ? attributes.collect do |attribute| 
          child = klass.new(attribute)
          child.parent = document
          child
        end : []
        super(@documents)
      end

    end
  end
end
