# encoding: utf-8
module Mongoid
  class Criteria
    module Modifiable

      # Build a document given the selector and return it.
      # Complex criteria, such as $in and $or operations will get ignored.
      #
      # @example build the document.
      #   Person.where(:title => "Sir").build
      #
      # @example Build with selectors getting ignored.
      #   Person.where(:age.gt => 5).build
      #
      # @return [ Document ] A non-persisted document.
      #
      # @since 2.0.0
      def build(mongo_context: Context.new(self), **attrs, &block)
        create_document(:new, attrs, mongo_context: mongo_context, &block)
      end
      alias :new :build

      # Create a document in the database given the selector and return it.
      # Complex criteria, such as $in and $or operations will get ignored.
      #
      # @example Create the document.
      #   Person.where(:title => "Sir").create
      #
      # @example Create with selectors getting ignored.
      #   Person.where(:age.gt => 5).create
      #
      # @return [ Document ] A newly created document.
      #
      # @since 2.0.0.rc.1
      def create(mongo_context: Context.new(self), **attrs, &block)
        create_document(:create, attrs, mongo_context: mongo_context, &block)
      end

      # Create a document in the database given the selector and return it.
      # Complex criteria, such as $in and $or operations will get ignored.
      # If validation fails, an error will be raised.
      #
      # @example Create the document.
      #   Person.where(:title => "Sir").create
      #
      # @example Create with selectors getting ignored.
      #   Person.where(:age.gt => 5).create
      #
      # @raise [ Errors::Validations ] on a validation error.
      #
      # @return [ Document ] A newly created document.
      #
      # @since 3.0.0
      def create!(mongo_context: Context.new(self), **attrs, &block)
        create_document(:create!, attrs, mongo_context: mongo_context, &block)
      end

      # Define attributes with which new documents will be created.
      #
      # @example Define attributes to be used when a new document is created.
      #   Person.create_with(job: 'Engineer').find_or_create_by(employer: 'MongoDB')
      #
      # @return [ Mongoid::Criteria ] A criteria.
      #
      # @since 5.1.0
      def create_with(mongo_context: Context.new(self), **attrs)
        where(selector.merge(attrs))
      end

      # Find the first +Document+ given the conditions, or creates a new document
      # with the conditions that were supplied.
      #
      # @example Find or create the document.
      #   Person.find_or_create_by(:attribute => "value")
      #
      # @param [ Hash ] attrs The attributes to check.
      #
      # @return [ Document ] A matching or newly created document.
      def find_or_create_by(mongo_context: Context.new(self), **attrs, &block)
        find_or(:create, mongo_context: mongo_context, **attrs, &block)
      end

      # Find the first +Document+ given the conditions, or creates a new document
      # with the conditions that were supplied. If validation fails an
      # exception will be raised.
      #
      # @example Find or create the document.
      #   Person.find_or_create_by!(:attribute => "value")
      #
      # @param [ Hash ] attrs The attributes to check.
      #
      # @raise [ Errors::Validations ] on validation error.
      #
      # @return [ Document ] A matching or newly created document.
      def find_or_create_by!(mongo_context: Context.new(self), **attrs, &block)
        find_or(:create!, mongo_context: mongo_context, **attrs, &block)
      end

      # Find the first +Document+ given the conditions, or initializes a new document
      # with the conditions that were supplied.
      #
      # @example Find or initialize the document.
      #   Person.find_or_initialize_by(:attribute => "value")
      #
      # @param [ Hash ] attrs The attributes to check.
      #
      # @return [ Document ] A matching or newly initialized document.
      def find_or_initialize_by(mongo_context: Context.new(self), **attrs, &block)
        find_or(:new, mongo_context: mongo_context, **attrs, &block)
      end

      # Find the first +Document+, or creates a new document
      # with the conditions that were supplied plus attributes.
      #
      # @example First or create the document.
      #   Person.where(name: "Jon").first_or_create(attribute: "value")
      #
      # @param [ Hash ] attrs The additional attributes to add.
      #
      # @return [ Document ] A matching or newly created document.
      #
      # @since 3.1.0
      def first_or_create(mongo_context: Context.new(self), **attrs, &block)
        first_or(:create, mongo_context: mongo_context, **attrs, &block)
      end

      # Find the first +Document+, or creates a new document
      # with the conditions that were supplied plus attributes and will
      # raise an error if validation fails.
      #
      # @example First or create the document.
      #   Person.where(name: "Jon").first_or_create!(attribute: "value")
      #
      # @param [ Hash ] attrs The additional attributes to add.
      #
      # @return [ Document ] A matching or newly created document.
      #
      # @since 3.1.0
      def first_or_create!(mongo_context: Context.new(self), **attrs, &block)
        first_or(:create!, mongo_context: mongo_context, **attrs, &block)
      end

      # Find the first +Document+, or initializes a new document
      # with the conditions that were supplied plus attributes.
      #
      # @example First or initialize the document.
      #   Person.where(name: "Jon").first_or_initialize(attribute: "value")
      #
      # @param [ Hash ] attrs The additional attributes to add.
      #
      # @return [ Document ] A matching or newly initialized document.
      #
      # @since 3.1.0
      def first_or_initialize(mongo_context: Context.new(self), **attrs, &block)
        first_or(:new, mongo_context: mongo_context, **attrs, &block)
      end

      private

      # Create a document given the provided method and attributes from the
      # existing selector.
      #
      # @api private
      #
      # @example Create a new document.
      #   criteria.create_document(:new, {})
      #
      # @param [ Symbol ] method Either :new or :create.
      # @param [ Hash ] attrs Additional attributes to use.
      #
      # @return [ Document ] The new or saved document.
      #
      # @since 3.0.0
      def create_document(method, attrs = nil, mongo_context: Context.new(self), &block)
        attributes = selector.reduce(attrs ? attrs.dup : {}) do |hash, (key, value)|
          unless key.to_s =~ /\$/ || value.is_a?(Hash)
            hash[key.to_sym] = value
          end
          hash
        end
        if embedded?
          attributes[:_parent] = parent_document
          attributes[:__metadata] = metadata
        end
        klass.__send__(method, attributes, &block)
      end

      # Find the first object or create/initialize it.
      #
      # @api private
      #
      # @example Find or perform an action.
      #   Person.find_or(:create, :name => "Dev")
      #
      # @param [ Symbol ] method The method to invoke.
      # @param [ Hash ] attrs The attributes to query or set.
      #
      # @return [ Document ] The first or new document.
      def find_or(method, mongo_context: Context.new(self), **attrs, &block)
        where(attrs).first ||
            send(method, mongo_context: mongo_context, **attrs, &block)
      end

      # Find the first document or create/initialize it.
      #
      # @api private
      #
      # @example First or perform an action.
      #   Person.first_or(:create, :name => "Dev")
      #
      # @param [ Symbol ] method The method to invoke.
      # @param [ Hash ] attrs The attributes to query or set.
      #
      # @return [ Document ] The first or new document.
      #
      # @since 3.1.0
      def first_or(method, mongo_context: Context.new(self), **attrs, &block)
        first || create_document(method, attrs, mongo_context: mongo_context, &block)
      end
    end
  end
end
