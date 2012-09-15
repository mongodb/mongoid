# encoding: utf-8
module Mongoid
  module Criterion
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
      def build(attrs = {})
        create_document(:new, attrs)
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
      def create(attrs = {})
        create_document(:create, attrs)
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
      def create!(attrs = {})
        create_document(:create!, attrs)
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
      def first_or_create(attrs = nil, &block)
        first_or(:create, attrs, &block)
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
      def first_or_create!(attrs = nil, &block)
        first_or(:create!, attrs, &block)
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
      def first_or_initialize(attrs = nil, &block)
        first_or(:new, attrs, &block)
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
      def create_document(method, attrs = nil)
        klass.__send__(method,
          selector.reduce(attrs || {}) do |hash, (key, value)|
            unless key.to_s =~ /\$/ || value.is_a?(Hash)
              hash[key] = value
            end
            hash
          end
        )
      end

      # Find the first document or create/initialize it.
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
      def first_or(method, attrs = nil)
        document = first || create_document(method, attrs)
        yield(document) if block_given?
        document
      end
    end
  end
end
