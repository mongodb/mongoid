# encoding: utf-8
module Mongoid #:nodoc:
  module Associations #:nodoc:
    # Represents embedding many documents within a parent document, which will
    # be an array as the underlying storage mechanism.
    class EmbedsMany < Proxy

      attr_accessor :association_name, :klass

      # Appends the object to the +Array+, setting its parent in
      # the process.
      def <<(*documents)
        documents.flatten.each do |doc|
          doc.parentize(@parent, @association_name)
          @target << doc
          doc._index = @target.size - 1
          doc.notify
        end
      end

      alias :concat :<<
      alias :push :<<

      # Builds a new Document and adds it to the association collection. The
      # document created will be of the same class as the others in the
      # association, and the attributes will be passed into the constructor.
      #
      # Returns:
      #
      # The newly created Document.
      def build(attrs = {}, type = nil)
        document = type ? type.instantiate : @klass.instantiate
        document.parentize(@parent, @association_name)
        document.write_attributes(attrs)
        @target << document
        document._index = @target.size - 1
        document
      end

      # Clears the association, and notifies the parents of the removal.
      def clear
        unless @target.empty?
          document = @target.first
          document.notify_observers(document, true)
          @target.clear
        end
      end

      # Creates a new Document and adds it to the association collection. The
      # document created will be of the same class as the others in the
      # association, and the attributes will be passed into the constructor and
      # the new object will then be saved.
      #
      # Returns:
      #
      # The newly created Document.
      def create(attrs = {}, type = nil)
        build(attrs, type).tap(&:save)
      end

      # Creates a new Document and adds it to the association collection. The
      # document created will be of the same class as the others in the
      # association, and the attributes will be passed into the constructor and
      # the new object will then be saved. If validation fails an error will
      # get raised.
      #
      # Returns:
      #
      # The newly created Document.
      def create!(attrs = {}, type = nil)
        document = create(attrs, type)
        errors = document.errors
        raise Errors::Validations.new(errors) unless errors.empty?
        document
      end

      # Delete all the documents in the association without running callbacks.
      #
      # Example:
      #
      # <tt>addresses.delete_all</tt>
      #
      # Returns:
      #
      # The number of documents deleted.
      def delete_all(conditions = {})
        remove(:delete, conditions)
      end

      # Delete all the documents in the association and run destroy callbacks.
      #
      # Example:
      #
      # <tt>addresses.destroy_all</tt>
      #
      # Returns:
      #
      # The number of documents destroyed.
      def destroy_all(conditions = {})
        remove(:destroy, conditions)
      end

      # Finds a document in this association.
      #
      # If :all is passed, returns all the documents
      #
      # If an id is passed, will return the document for that id.
      #
      # Returns:
      #
      # Array or single Document.
      def find(param)
        return @target if param == :all
        return detect { |document| document.id == param }
      end

      # Creates the new association by finding the attributes in
      # the parent document with its name, and instantiating a
      # new document for each one found. These will then be put in an
      # internal array.
      #
      # This then delegated all methods to the array class since this is
      # essentially a proxy to an array itself.
      #
      # Options:
      #
      # parent: The parent document to the association.
      # options: The association options.
      def initialize(parent, options)
        @parent, @association_name = parent, options.name
        @klass, @options = options.klass, options
        initialize_each(parent.raw_attributes[@association_name])
        extends(options)
      end

      # If the target array does not respond to the supplied method then try to
      # find a named scope or criteria on the class and send the call there.
      #
      # If the method exists on the array, use the default proxy behavior.
      def method_missing(name, *args, &block)
        unless @target.respond_to?(name)
          object = @klass.send(name, *args)
          object.documents = @target
          return object
        end
        super
      end

      # Used for setting associations via a nested attributes setter from the
      # parent +Document+.
      #
      # Options:
      #
      # attributes: A +Hash+ of integer keys and +Hash+ values.
      #
      # Returns:
      #
      # The newly build target Document.
      def nested_build(attributes, options = {})
        attributes.each do |index, attrs|
          if document = detect { |document| document._index == index.to_i }
            if options && options[:allow_destroy] && attrs['_destroy']
              @target.delete(document)
              document.destroy
            else
              document.write_attributes(attrs)
            end
          else
            build(attrs)
          end
        end
      end

      # Paginate the association. Will create a new criteria, set the documents
      # on it and execute in an enumerable context.
      #
      # Options:
      #
      # options: A +Hash+ of pagination options.
      #
      # Returns:
      #
      # A +WillPaginate::Collection+.
      def paginate(options)
        criteria = Mongoid::Criteria.translate(@klass, options)
        criteria.documents = @target
        criteria.paginate(options)
      end

      protected
      # Initializes each of the attributes in the hash.
      def initialize_each(attributes)
        @target = []
        if attributes
          attributes.each_with_index do |attrs, index|
            klass = attrs.klass
            child = klass ? klass.instantiate(attrs) : @klass.instantiate(attrs)
            child.parentize(@parent, @association_name)
            child._index = index
            @target << child
          end
        end
      end

      # Removes documents based on a method.
      def remove(method, conditions)
        criteria = @klass.find(conditions || {})
        criteria.documents = @target
        count = criteria.size
        criteria.each do |doc|
          @target.delete(doc); doc.send(method)
        end; count
      end

      class << self

        # Preferred method of creating a new +EmbedsMany+ association. It will
        # delegate to new.
        #
        # Options:
        #
        # document: The parent +Document+
        # options: The association options
        def instantiate(document, options)
          new(document, options)
        end

        # Returns the macro used to create the association.
        def macro
          :embeds_many
        end

        # Perform an update of the relationship of the parent and child. This
        # is initialized by setting the has_many to the supplied +Enumerable+
        # and setting up the parentization.
        def update(children, parent, options)
          parent.remove_attribute(options.name)
          children.assimilate(parent, options)
          instantiate(parent, options)
        end
      end
    end
  end
end
