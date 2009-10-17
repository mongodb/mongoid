module Mongoid #:nodoc:
  module Associations #:nodoc:
    class HasManyAssociation < DelegateClass(Array) #:nodoc:

      # Appends the object to the +Array+, setting its parent in
      # the process.
      def <<(object)
        object.parentize(@parent)
        @documents << object
      end

      # Appends the object to the +Array+, setting its parent in
      # the process.
      def push(object)
        self << object
      end

      # Appends the object to the +Array+, setting its parent in
      # the process.
      def concat(object)
        self << object
      end

      # Builds a new Document and adds it to the association collection. The
      # document created will be of the same class as the others in the
      # association, and the attributes will be passed into the constructor.
      #
      # Returns the newly created object.
      def build(attributes)
        object = @klass.new(attributes)
        push(object)
        object
      end

      # Finds a document in this association.
      # If :all is passed, returns all the documents
      # If an id is passed, will return the document for that id.
      def find(param)
        return @documents if param == :all
        return detect { |document| document.id == param }
      end

      # Creates the new association by finding the attributes in
      # the parent document with its name, and instantiating a
      # new document for each one found. These will then be put in an
      # internal array.
      #
      # This then delegated all methods to the array class since this is
      # essentially a proxy to an array itself.
      def initialize(association_name, document)
        @parent = document
        @klass = association_name.to_s.classify.constantize
        attributes = document.attributes[association_name]
        @documents = attributes ? attributes.collect do |attribute|
          child = @klass.new(attribute)
          child.parent = document
          child
        end : []
        super(@documents)
      end

    end
  end
end
