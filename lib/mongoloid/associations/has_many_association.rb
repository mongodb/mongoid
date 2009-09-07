module Mongoloid
  module Associations
    class HasManyAssociation < DelegateClass(Array)

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
        @documents = []
        attributes.each { |attribute| @documents << klass.new(attribute) } if attributes
        super(@documents)
      end

    end
  end
end