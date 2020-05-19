# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  class Criteria
    module Modifiable

      # @attribute [r] create_attrs Additional attributes to add to the Document upon creation.
      # @api private
      attr_reader :create_attrs

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
      def build(attrs = {}, &block)
        create_document(:new, attrs, &block)
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
      def create(attrs = {}, &block)
        create_document(:create, attrs, &block)
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
      def create!(attrs = {}, &block)
        create_document(:create!, attrs, &block)
      end

      # Define attributes with which new documents will be created.
      #
      # Note that if `find_or_create_by` is called after this in a method chain, the attributes in
      # the query will override those from this method.
      #
      # @example Define attributes to be used when a new document is created.
      #   Person.create_with(job: 'Engineer').find_or_create_by(employer: 'MongoDB')
      #
      # @return [ Mongoid::Criteria ] A criteria.
      #
      # @since 5.1.0
      def create_with(attrs = {})
        tap do
          @create_attrs ||= {}
          @create_attrs.update(attrs)
        end
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
      def find_or_create_by(attrs = {}, &block)
        find_or(:create, attrs, &block)
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
      def find_or_create_by!(attrs = {}, &block)
        find_or(:create!, attrs, &block)
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
      def find_or_initialize_by(attrs = {}, &block)
        find_or(:new, attrs, &block)
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
      def create_document(method, attrs = nil, &block)
        attrs = (create_attrs || {}).merge(attrs || {})
        attributes = selector.reduce(attrs) do |hash, (key, value)|
          unless invalid_key?(hash, key) || invalid_embedded_doc?(value)
            hash[key] = value
          end
          hash
        end
        if embedded?
          attributes[:_parent] = parent_document
          attributes[:_association] = association
        end
        if polymorphic? && @criterion
          klass.__send__(method, attributes.merge(@criterion), &block)
        else
          klass.__send__(method, attributes, &block)
        end
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
      def find_or(method, attrs = {}, &block)
        where(attrs).first || send(method, attrs, &block)
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
      def first_or(method, attrs = {}, &block)
        first || create_document(method, attrs, &block)
      end

      private

      def invalid_key?(hash, key)
        # @todo Change this to BSON::String::ILLEGAL_KEY when ruby driver 2.3.0 is
        # released and mongoid is updated to depend on driver >= 2.3.0
        key.to_s =~ Mongoid::Document::ILLEGAL_KEY || hash.key?(key.to_sym) || hash.key?(key)
      end

      def invalid_embedded_doc?(value)
        # @todo Change this to BSON::String::ILLEGAL_KEY when ruby driver 2.3.0 is
        # released and mongoid is updated to depend on driver >= 2.3.0
        value.is_a?(Hash) && value.any? do |key, v|
          key.to_s =~ Mongoid::Document::ILLEGAL_KEY || invalid_embedded_doc?(v)
        end
      end
    end
  end
end
