# encoding: utf-8
module Mongoid #:nodoc:
  module Associations #:nodoc:
    # Represents an relational one-to-many association with an object in a
    # separate collection or database.
    class ReferencesMany < Proxy

      # Appends the object to the +Array+, setting its parent in
      # the process.
      def <<(*objects)
        load_target
        objects.flatten.each do |object|
          object.send("#{@foreign_key}=", @parent.id)
          @target << object
          object.save unless @parent.new_record?
        end
      end

      alias :concat :<<
      alias :push :<<

      # Builds a new Document and adds it to the association collection. The
      # document created will be of the same class as the others in the
      # association, and the attributes will be passed into the constructor.
      #
      # Returns the newly created object.
      def build(attributes = nil)
        load_target
        name = @parent.class.to_s.underscore
        object = @klass.instantiate((attributes || {}).merge(name => @parent))
        @target << object
        object
      end

      # Creates a new Document and adds it to the association collection. The
      # document created will be of the same class as the others in the
      # association, and the attributes will be passed into the constructor and
      # the new object will then be saved.
      #
      # Returns the newly created object.
      def create(attributes)
        build(attributes).tap(&:save)
      end

      # Creates a new Document and adds it to the association collection. If
      # validation fails an error is raised.
      #
      # Returns the newly created object.
      def create!(attributes)
        build(attributes).tap(&:save!)
      end

      # Delete all the associated objects.
      #
      # Example:
      #
      # <tt>person.posts.delete_all</tt>
      #
      # Returns:
      #
      # The number of objects deleted.
      def delete_all(conditions = {})
        remove(:delete_all, conditions[:conditions])
      end

      # Destroy all the associated objects.
      #
      # Example:
      #
      # <tt>person.posts.destroy_all</tt>
      #
      # Returns:
      #
      # The number of objects destroyed.
      def destroy_all(conditions = {})
        remove(:destroy_all, conditions[:conditions])
      end

      # Finds a document in this association.
      # If an id is passed, will return the document for that id.
      def find(id_or_type, options = {})
        return self.id_criteria(id_or_type) unless id_or_type.is_a?(Symbol)
        options[:conditions] = (options[:conditions] || {}).merge(@foreign_key.to_sym => @parent.id)
        @klass.find(id_or_type, options)
      end

      # Initializing a related association only requires looking up the objects
      # by their ids.
      #
      # Options:
      #
      # document: The +Document+ that contains the relationship.
      # options: The association +Options+.
      def initialize(document, options, target = nil)
        setup(document, options)
        @target = target || query.call
      end

      # Override the default behavior to allow the criteria to get reset on
      # each call into the association.
      #
      # Example:
      #
      #   person.posts.where(:title => "New")
      #   person.posts # resets the criteria
      #
      # Returns:
      #
      # A Criteria object or Array.
      def method_missing(name, *args, &block)
        @target = query.call unless @target.is_a?(Array)
        @target.send(name, *args, &block)
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
          begin
            document = find(index.to_i)
            if options && options[:allow_destroy] && attrs['_destroy']
              @target.delete(document)
              document.destroy
            else
              document.write_attributes(attrs)
            end
          rescue Errors::DocumentNotFound
            build(attrs)
          end
        end
      end

      protected
      # Load the target entries if the parent document is new.
      def load_target
        @target = @target.entries if @parent.new_record?
      end

      # The default query used for retrieving the documents from the database.
      # In this case we use the common API between Mongoid, ActiveRecord, and
      # DataMapper so we can do one-to-many relationships with data in other
      # databases.
      #
      # Example:
      #
      # <tt>association.query</tt>
      #
      # Returns:
      #
      #   A +Criteria+ if a Mongoid association.
      #   An +Array+ of objects if an ActiveRecord association
      #   A +Collection+ if a DataMapper association.
      def query
        @query ||= lambda { @klass.all(:conditions => { @foreign_key => @parent.id }) }
      end

      # Remove the objects based on conditions.
      def remove(method, conditions)
        selector = { @foreign_key => @parent.id }.merge(conditions || {})
        removed = @klass.send(method, :conditions => selector)
        reset; removed
      end

      # Reset the memoized association on the parent. This will execute the
      # database query again.
      #
      # Example:
      #
      # <tt>association.reset</tt>
      #
      # Returns:
      #
      # See #query rdoc for return values.
      def reset
        @parent.send(:reset, @options.name) { query.call }
      end

      class << self
        # Preferred method for creating the new +ReferencesMany+ association.
        #
        # Options:
        #
        # document: The +Document+ that contains the relationship.
        # options: The association +Options+.
        def instantiate(document, options, target = nil)
          new(document, options, target)
        end

        # Returns the macro used to create the association.
        def macro
          :references_many
        end

        # Perform an update of the relationship of the parent and child. This
        # will assimilate the child +Document+ into the parent's object graph.
        #
        # Options:
        #
        # related: The related object
        # parent: The parent +Document+ to update.
        # options: The association +Options+
        #
        # Example:
        #
        # <tt>RelatesToOne.update(game, person, options)</tt>
        def update(target, document, options)
          name = document.class.to_s.underscore
          target.each { |child| child.send("#{name}=", document) }
          instantiate(document, options, target)
        end
      end
    end
  end
end
