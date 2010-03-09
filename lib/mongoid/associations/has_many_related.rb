# encoding: utf-8
module Mongoid #:nodoc:
  module Associations #:nodoc:
    class HasManyRelated #:nodoc:
      include Proxy

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

      # Builds a new Document and adds it to the association collection. The
      # document created will be of the same class as the others in the
      # association, and the attributes will be passed into the constructor.
      #
      # Returns the newly created object.
      def build(attributes = {})
        load_target
        name = @parent.class.to_s.underscore
        object = @klass.instantiate(attributes.merge(name => @parent))
        @target << object
        object
      end

      # Delegates to <<
      def concat(*objects)
        self << objects
      end

      # Creates a new Document and adds it to the association collection. The
      # document created will be of the same class as the others in the
      # association, and the attributes will be passed into the constructor and
      # the new object will then be saved.
      #
      # Returns the newly created object.
      def create(attributes)
        object = build(attributes)
        object.save
        object
      end

      # Finds a document in this association.
      # If an id is passed, will return the document for that id.
      def find(*args)
        args[1][:conditions].merge!(@foreign_key.to_sym => @parent.id) if args.size > 1
        @klass.find(*args)
      end

      # Initializing a related association only requires looking up the objects
      # by their ids.
      #
      # Options:
      #
      # document: The +Document+ that contains the relationship.
      # options: The association +Options+.
      def initialize(document, options, target = nil)
        @parent, @klass = document, options.klass
        @foreign_key = options.foreign_key
        @target = target || @klass.all(:conditions => { @foreign_key => document.id })
        extends(options)
      end

      # Delegates to <<
      def push(*objects)
        self << objects
      end

      protected
      # Load the target entries if the document is new.
      def load_target
        @target = @target.entries if @parent.new_record?
      end

      class << self
        # Preferred method for creating the new +HasManyRelated+ association.
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
          :has_many_related
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
