# encoding: utf-8
module Mongoid #:nodoc:
  module Relations #:nodoc:

    # This is the superclass for all many to one and many to many relation
    # proxies.
    class Many < Proxy

      delegate :avg, :max, :min, :sum, :to => :criteria

      # Appends a document or array of documents to the relation. Will set
      # the parent and update the index in the process.
      #
      # @example Append a document.
      #   person.addresses << address
      #
      # @example Push a document.
      #   person.addresses.push(address)
      #
      # @example Concat with other documents.
      #   person.addresses.concat([ address_one, address_two ])
      #
      # @param [ Document, Array<Document> ] *args Any number of documents.
      def <<(*args)
        options = default_options(args)
        args.flatten.each do |doc|
          return doc unless doc
          append(doc, options)
          doc.save if base.persisted? && !options[:binding]
        end
      end
      alias :concat :<<
      alias :push :<<

      # Builds a new document in the relation and appends it to the target.
      # Takes an optional type if you want to specify a subclass.
      #
      # @example Build a new document on the relation.
      #   person.people.build(:name => "Bozo")
      #
      # @param [ Hash ] attributes The attributes to build the document with.
      # @param [ Class ] type Optional class to build the document with.
      #
      # @return [ Document ] The new document.
      def build(attributes = {}, type = nil, &block)
        instantiated(type).tap do |doc|
          doc.write_attributes(attributes)
          doc.identify
          append(doc, default_options(:binding => true))
          block.call(doc) if block
          doc.run_callbacks(:build) { doc }
        end
      end
      alias :new :build

      # Creates a new document on the references many relation. This will
      # save the document if the parent has been persisted.
      #
      # @example Create and save the new document.
      #   person.posts.create(:text => "Testing")
      #
      # @param [ Hash ] attributes The attributes to create with.
      # @param [ Class ] type The optional type of document to create.
      #
      # @return [ Document ] The newly created document.
      def create(attributes = nil, type = nil, &block)
        build(attributes, type).tap do |doc|
          block.call(doc) if block
          doc.save if base.persisted?
        end
      end

      # Creates a new document on the references many relation. This will
      # save the document if the parent has been persisted and will raise an
      # error if validation fails.
      #
      # @example Create and save the new document.
      #   person.posts.create!(:text => "Testing")
      #
      # @param [ Hash ] attributes The attributes to create with.
      # @param [ Class ] type The optional type of document to create.
      #
      # @raise [ Errors::Validations ] If validation failed.
      #
      # @return [ Document ] The newly created document.
      def create!(attributes = nil, type = nil)
        build(attributes, type).tap do |doc|
          doc.save! if base.persisted?
        end
      end

      # Determine if any documents in this relation exist in the database.
      #
      # @example Are there persisted documents?
      #   person.posts.exists?
      #
      # @return [ true, false ] True is persisted documents exist, false if not.
      def exists?
        count > 0
      end

      # Find the first document given the conditions, or creates a new document
      # with the conditions that were supplied.
      #
      # @example Find or create.
      #   person.posts.find_or_create_by(:title => "Testing")
      #
      # @param [ Hash ] attrs The attributes to search or create with.
      #
      # @return [ Document ] An existing document or newly created one.
      def find_or_create_by(attrs = {}, &block)
        find_or(:create, attrs, &block)
      end

      # Find the first +Document+ given the conditions, or instantiates a new document
      # with the conditions that were supplied
      #
      # @example Find or initialize.
      #   person.posts.find_or_initialize_by(:title => "Test")
      #
      # @param [ Hash ] attrs The attributes to search or initialize with.
      #
      # @return [ Document ] An existing document or newly instantiated one.
      def find_or_initialize_by(attrs = {}, &block)
        find_or(:build, attrs, &block)
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
      def respond_to?(name)
        [].respond_to?(name) || methods.include?(name)
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

      # Always returns the number of documents that are in memory.
      #
      # @example Get the number of loaded documents.
      #   relation.size
      #
      # @return [ Integer ] The number of documents in memory.
      #
      # @since 2.0.0
      def size
        target.size
      end
      alias :length :size

      private

      # Get the default options used in binding functions.
      #
      # @example Get the default options.
      #   relation.default_options(:continue => true)
      #
      # @param [ Hash, Array ] args The arguments to parse from.
      #
      # @return [ Hash ] The options merged with the actuals.
      def default_options(args = {})
        options = args.is_a?(Hash) ? args : args.extract_options!
        Mongoid.binding_defaults.merge(options)
      end

      # Find the first object given the supplied attributes or create/initialize it.
      #
      # @example Find or create|initialize.
      #   person.addresses.find_or(:create, :street => "Bond")
      #
      # @param [ Symbol ] method The method name, create or new.
      # @param [ Hash ] attrs The attributes to build with.
      #
      # @return [ Document ] A matching document or a new/created one.
      def find_or(method, attrs = {}, &block)
        find(:first, :conditions => attrs) || send(method, attrs, &block)
      end
    end
  end
end
