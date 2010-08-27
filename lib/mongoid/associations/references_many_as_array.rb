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
        @target = @target.entries
        objects.flatten.each do |object|
          # First set the documents id on the parent array of ids.
          @parent.send(@foreign_key) << object.id
          # Then we need to set the parent's id on the documents array of ids
          # to get the inverse side of the association as well. Note, need a
          # clean way to handle this with new documents - we want to set the
          # actual objects as well, but dont want to get in an infinite loop
          # while doing so.
          if inverse?
            reverse_key = reverse_key(object)
            case inverse_of(object).macro
            when :references_many
              object.send(reverse_key) << @parent.id
            when :referenced_in
              object.send("#{reverse_key}=", @parent.id)
            end
          end
          @target << object
          object.save unless @parent.new_record?
        end
        @parent.save unless @parent.new_record?
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
        removed = query.call.destroy_all(:conditions => conditions)
        reset; removed
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
        removed = query.call.delete_all(:conditions => conditions)
        reset; removed
      end

      protected

      # Find the inverse key for the supplied document.
      def reverse_key(document)
        inverse_of(document).options.foreign_key
      end

      # Returns +true+ if there is an inverse association on the referenced
      # model.
      def inverse?
        !!@options.inverse_of
      end

      # Returns the association on +document+ which is the inverse of this
      # association.
      def inverse_of(document)
        document.class.associations[@options.inverse_of.to_s]
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
        # <tt>ReferencesManyAsArray.update(preferences, person, options)</tt>
        def update(target, document, options)
          target.each do |child|
            document.send(options.name) << child
          end
          instantiate(document, options, target)
        end
      end
    end
  end
end
