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
          document._parent.update_child(document, true) if (document._parent)
          @target.clear
        end
      end

      # Returns a count of the number of documents in the association that have
      # actually been persisted to the database.
      #
      # Use #size if you want the total number of documents.
      #
      # Returns:
      #
      # The total number of persisted embedded docs, as flagged by the
      # #persisted? method.
      def count
        @target.select(&:persisted?).size
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
        raise Errors::Validations.new(document) unless document.errors.empty?
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
        criteria.id(param).first
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
      def initialize(parent, options, target_array = nil)
        @parent, @association_name = parent, options.name
        @klass, @options = options.klass, options
        if target_array
          build_children_from_target_array(target_array)
        else
          build_children_from_attributes(parent.raw_attributes[@association_name])
        end
        extends(options)
      end

      # If the target array does not respond to the supplied method then try to
      # find a named scope or criteria on the class and send the call there.
      #
      # If the method exists on the array, use the default proxy behavior.
      def method_missing(name, *args, &block)
        if @target.respond_to?(name)
          super
        else
          @klass.send(:with_scope, criteria) do
            object = @klass.send(name, *args)
          end
        end
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
        @parent.instance_variable_set(:@building_nested, true)
        id_index, reordering = {}, false
        attributes.each do |index, attrs|
          document = if attrs["id"].present?
            reordering = true
            id_index[attrs["id"]] = index.to_i
            detect { |document| document.id.to_s == attrs["id"].to_s }
          else
            detect { |document| document._index == index.to_i }
          end
          if document
            if options && options[:allow_destroy] && Boolean.set(attrs['_destroy'])
              @target.delete(document)
              document.destroy
            else
              document.write_attributes(attrs)
            end
          else
            document = build(attrs)
            id_index[document.id.to_s] = index.to_i
          end
        end
        if reordering
          @target.sort! do |a, b|
            ai, bi = id_index[a.id.to_s], id_index[b.id.to_s]
            ai.nil? ? (bi.nil? ? 0 : 1) : (bi.nil? ? -1 : ai <=> bi)
          end
        end
        @target.each_with_index { |document, index| document._index = index }
        @parent.instance_variable_set(:@building_nested, false)
        self
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
      def build_children_from_attributes(attributes)
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

      # Initializes the target array from an existing array of documents.
      def build_children_from_target_array(target_array)
        @target = target_array
        @target.each_with_index do |child, index|
          child._index = index
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

      # Returns the criteria object for the target class with its documents set
      # to @target.
      def criteria
        criteria = @klass.criteria
        criteria.documents = @target
        criteria
      end

      class << self
        # Returns the macro used to create the association.
        def macro
          :embeds_many
        end

        # Perform an update of the relationship of the parent and child. This
        # is initialized by setting the has_many to the supplied +Enumerable+
        # and setting up the parentization.
        def update(children, parent, options)
          parent.raw_attributes.delete(options.name)
          children.assimilate(parent, options)
          if children && children.first.is_a?(Mongoid::Document)
            new(parent, options, children)
          else
            new(parent, options)
          end
        end

        # Validate the options passed to the embeds many macro, to encapsulate
        # the behavior in this class instead of the associations module.
        #
        # Options:
        #
        # options: Thank you captain obvious.
        def validate_options(options = {})
          check_dependent_not_allowed!(options)
          check_inverse_not_allowed!(options)
        end
      end
    end
  end
end
