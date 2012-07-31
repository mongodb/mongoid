# encoding: utf-8
module Mongoid
  module Relations

    # This is the superclass for all many to one and many to many relation
    # proxies.
    class Many < Proxy

      delegate :avg, :max, :min, :sum, to: :criteria
      delegate :length, :size, to: :target

      # Is the relation empty?
      #
      # @example Is the relation empty??
      #   person.addresses.blank?
      #
      # @return [ true, false ] If the relation is empty or not.
      #
      # @since 2.1.0
      def blank?
        size == 0
      end

        # Creates a new document on the references many relation. This will
        # save the document if the parent has been persisted.
        #
        # @example Create and save the new document.
        #   person.posts.create(:text => "Testing")
      #
      # @overload create(attributes = nil, options = {}, type = nil)
      #   @param [ Hash ] attributes The attributes to create with.
      #   @param [ Hash ] options The scoped assignment options.
      #   @param [ Class ] type The optional type of document to create.
      #
      # @overload create(attributes = nil, type = nil)
      #   @param [ Hash ] attributes The attributes to create with.
      #   @param [ Class ] type The optional type of document to create.
      #
      # @return [ Document ] The newly created document.
      #
      # @since 2.0.0.beta.1
      def create(attributes = nil, options = {}, type = nil, &block)
        doc = build(attributes, options, type, &block)
        base.persisted? ? doc.save : raise_unsaved(doc)
        doc
      end

      # Creates a new document on the references many relation. This will
      # save the document if the parent has been persisted and will raise an
      # error if validation fails.
      #
      # @example Create and save the new document.
      #   person.posts.create!(:text => "Testing")
      #
      # @overload create!(attributes = nil, options = {}, type = nil)
      #   @param [ Hash ] attributes The attributes to create with.
      #   @param [ Hash ] options The scoped assignment options.
      #   @param [ Class ] type The optional type of document to create.
      #
      # @overload create!(attributes = nil, type = nil)
      #   @param [ Hash ] attributes The attributes to create with.
      #   @param [ Class ] type The optional type of document to create.
      #
      # @raise [ Errors::Validations ] If validation failed.
      #
      # @return [ Document ] The newly created document.
      #
      # @since 2.0.0.beta.1
      def create!(attributes = nil, options = {}, type = nil, &block)
        doc = build(attributes, options, type, &block)
        base.persisted? ? doc.save! : raise_unsaved(doc)
        doc
      end

      # Find the first document given the conditions, or creates a new document
      # with the conditions that were supplied.
      #
      # @example Find or create.
      #   person.posts.find_or_create_by(:title => "Testing")
      #
      # @overload find_or_create_by(attributes = nil, options = {}, type = nil)
      #   @param [ Hash ] attributes The attributes to search or create with.
      #   @param [ Hash ] options The scoped assignment options.
      #   @param [ Class ] type The optional type of document to create.
      #
      # @overload find_or_create_by(attributes = nil, type = nil)
      #   @param [ Hash ] attributes The attributes to search or create with.
      #   @param [ Class ] type The optional type of document to create.
      #
      # @return [ Document ] An existing document or newly created one.
      def find_or_create_by(attrs = {}, options = {}, type = nil, &block)
        find_or(:create, attrs, options, type, &block)
      end

      # Find the first +Document+ given the conditions, or instantiates a new document
      # with the conditions that were supplied
      #
      # @example Find or initialize.
      #   person.posts.find_or_initialize_by(:title => "Test")
      #
      # @overload find_or_initialize_by(attributes = {}, options = {}, type = nil)
      #   @param [ Hash ] attributes The attributes to search or initialize with.
      #   @param [ Hash ] options The scoped assignment options.
      #   @param [ Class ] type The optional subclass to build.
      #
      # @overload find_or_initialize_by(attributes = {}, type = nil)
      #   @param [ Hash ] attributes The attributes to search or initialize with.
      #   @param [ Class ] type The optional subclass to build.
      #
      # @return [ Document ] An existing document or newly instantiated one.
      def find_or_initialize_by(attrs = {}, options = {}, type = nil, &block)
        find_or(:build, attrs, options, type, &block)
      end

      # This proxy can never be nil.
      #
      # @example Is the proxy nil?
      #   relation.nil?
      #
      # @return [ false ] Always false.
      #
      # @since 2.0.0
      def nil?
        false
      end

      # Since method_missing is overridden we should override this as well.
      #
      # @example Does the proxy respond to the method?
      #   relation.respond_to?(:name)
      #
      # @param [ Symbol ] name The method name.
      #
      # @return [ true, false ] If the proxy responds to the method.
      #
      # @since 2.0.0
      def respond_to?(name, include_private = false)
        [].respond_to?(name, include_private) ||
          klass.respond_to?(name, include_private) || super
      end

      # This is public access to the relation's criteria.
      #
      # @example Get the scoped relation.
      #   relation.scoped
      #
      # @return [ Criteria ] The scoped criteria.
      #
      # @since 2.1.0
      def scoped
        criteria
      end

      # Gets the document as a serializable hash, used by ActiveModel's JSON and
      # XML serializers. This override is just to be able to pass the :include
      # and :except options to get associations in the hash.
      #
      # @example Get the serializable hash.
      #   relation.serializable_hash
      #
      # @param [ Hash ] options The options to pass.
      #
      # @option options [ Symbol ] :include What relations to include
      # @option options [ Symbol ] :only Limit the fields to only these.
      # @option options [ Symbol ] :except Dont include these fields.
      #
      # @return [ Hash ] The documents, ready to be serialized.
      #
      # @since 2.0.0.rc.6
      def serializable_hash(options = {})
        target.map { |document| document.serializable_hash(options) }
      end

      # Get a criteria for the embedded documents without the default scoping
      # applied.
      #
      # @example Get the unscoped criteria.
      #   person.addresses.unscoped
      #
      # @return [ Criteria ] The unscoped criteria.
      #
      # @since 2.4.0
      def unscoped
        criteria.unscoped
      end

      private

      # Find the first object given the supplied attributes or create/initialize it.
      #
      # @example Find or create|initialize.
      #   person.addresses.find_or(:create, :street => "Bond")
      #
      # @overload find_or(method, attributes = {}, options = {}, type = nil)
      #   @param [ Symbol ] method The method name, create or new.
      #   @param [ Hash ] attributes The attributes to search or build with.
      #   @param [ Hash ] options The scoped assignment options.
      #   @param [ Class ] type The optional subclass to build.
      #
      # @overload find_or(attributes = {}, type = nil)
      #   @param [ Symbol ] method The method name, create or new.
      #   @param [ Hash ] attributes The attributes to search or build with.
      #   @param [ Class ] type The optional subclass to build.
      #
      # @return [ Document ] A matching document or a new/created one.
      def find_or(method, attrs = {}, options = {}, type = nil, &block)
        if options.is_a? Class
          options, type = {}, options
        end

        attrs["_type"] = type.to_s if type

        where(attrs).first || send(method, attrs, options, type, &block)
      end
    end
  end
end
