# encoding: utf-8
module Mongoid #:nodoc:
  module Associations #:nodoc:
    # Represents an relational one-to-many association with an object in a
    # separate collection or database, stored as an array of ids on the parent
    # document.
    class ReferencesManyAsArray < ReferencesMany

      # Append a document to this association. This will also set the appended
      # document's id on the inverse association as well.
      #
      # Example:
      #
      # <tt>person.preferences << Preference.new(:name => "VGA")</tt>
      def <<(*objects)
        load_target
        objects.flatten.each do |object|
          # First set the documents id on the parent array of ids.
          @parent.send(@foreign_key) << object.id
          # Then we need to set the parent's id on the documents array of ids
          # to get the inverse side of the association as well.
          object.send(reverse_key(object)) << @parent.id
          @target << object
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
        document = @klass.instantiate(attributes || {})
        push(document); document
      end

      protected
      # Find the inverse key for the supplied document.
      def reverse_key(document)
        document.send(@options.inverse_of).options.foreign_key
      end

      # The default query used for retrieving the documents from the database.
      def query
        @query ||= lambda { @klass.any_in(:_id => @parent.send(@foreign_key)) }
      end

      class << self
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
        # <tt>RelatesToManyAsArray.update(preferences, person, options)</tt>
        def update(target, document, options)
          target.each do |child|
            name = child.associations[options.inverse_of.to_s].options.name
            child.send(name) << document
          end
          instantiate(document, options, target)
        end
      end
    end
  end
end
