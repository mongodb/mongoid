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
          object.write_attribute(@foreign_key, @parent.id)
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
        name = determine_name
        object = @klass.instantiate(attributes || {})
        object.send("#{name}=", @parent)
        @target << object
        object
      end

      # Creates a new Document and adds it to the association collection. The
      # document created will be of the same class as the others in the
      # association, and the attributes will be passed into the constructor and
      # the new object will then be saved.
      #
      # Returns the newly created object.
      def create(attributes = nil)
        build(attributes).tap(&:save)
      end

      # Creates a new Document and adds it to the association collection. If
      # validation fails an error is raised.
      #
      # Returns the newly created object.
      def create!(attributes = nil)
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
            _destroy = Boolean.set(attrs.delete('_destroy'))
            document = find(attrs.delete("id"))
            if options && options[:allow_destroy] && _destroy
              @target.delete(document)
              document.destroy
            else
              document.update_attributes(attrs)
            end
          rescue Errors::DocumentNotFound
            create(attrs)
          end
        end
      end

      protected
      # Load the target entries if the parent document is new.
      def load_target
        @target = @target.entries if @parent.new_record?
      end

      def determine_name
        @proxy ||= class << self; self; end
        @proxy.send(:determine_name, @parent, @options)
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
        @query ||= lambda {
          @klass.all(:conditions => { @foreign_key => @parent.id }).tap do |crit|
            crit.set_order_by(@options.default_order) if @options.default_order
          end
        }
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
          name = determine_name(document, options)
          target.each { |child| child.send("#{name}=", document) }
          instantiate(document, options, target)
        end

        protected
        def determine_name(document, options)
          target = document.class
          if (inverse = options.inverse_of) && inverse.is_a?(Array)
            inverse = [*inverse].detect { |name| target.respond_to?(name) }
          end
          if !inverse
            association = detect_association(target, options, false)
            association = detect_association(target, options, true) if association.blank?
            inferred = association.name if association
          end
          inverse || inferred || target.to_s.underscore
        end

        def detect_association(target, options, with_class_name = false)
          association = options.klass.associations.values.detect do |metadata|
            metadata.options.klass == target &&
              (with_class_name ? true : metadata.options[:class_name].nil?)
          end
        end
      end
    end
  end
end
