# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Association

    # This is the superclass for all many to one and many to many association
    # proxies.
    class Many < Association::Proxy
      extend Forwardable
      include ::Enumerable

      def_delegators :criteria, :avg, :max, :min, :sum
      def_delegators :_target, :length, :size, :any?

      # Is the association empty?
      #
      # @example Is the association empty??
      #   person.addresses.blank?
      #
      # @return [ true | false ] If the association is empty or not.
      def blank?
        !any?
      end

      # Creates a new document on the references many association. This will
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
        if attributes.is_a?(::Array)
          attributes.map { |attrs| create(attrs, type, &block) }
        else
          doc = build(attributes, type, &block)
          _base.persisted? ? doc.save : raise_unsaved(doc)
          doc
        end
      end

      # Creates a new document on the references many association. This will
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
      def create!(attributes = nil, type = nil, &block)
        if attributes.is_a?(::Array)
          attributes.map { |attrs| create!(attrs, type, &block) }
        else
          doc = build(attributes, type, &block)

          Array(doc).each do |doc|
            doc.try(:run_pending_callbacks)
          end

          _base.persisted? ? doc.save! : raise_unsaved(doc)
          doc
        end
      end

      # Find the first document given the conditions, or creates a new document
      # with the conditions that were supplied.
      #
      # @example Find or create.
      #   person.posts.find_or_create_by(:title => "Testing")
      #
      #  @param [ Hash ] attrs The attributes to search or create with.
      #  @param [ Class ] type The optional type of document to create.
      #
      # @return [ Document ] An existing document or newly created one.
      def find_or_create_by(attrs = {}, type = nil, &block)
        find_or(:create, attrs, type, &block)
      end

      # Find the first document given the conditions, or creates a new document
      # with the conditions that were supplied. This will raise an error if validation fails.
      #
      # @example Find or create.
      #   person.posts.find_or_create_by!(:title => "Testing")
      #
      # @param [ Hash ] attrs The attributes to search or create with.
      # @param [ Class ] type The optional type of document to create.
      #
      # @raise [ Errors::Validations ] If validation failed.
      #
      # @return [ Document ] An existing document or newly created one.
      def find_or_create_by!(attrs = {}, type = nil, &block)
        find_or(:create!, attrs, type, &block)
      end

      # Find the first +Document+ given the conditions, or instantiates a new document
      # with the conditions that were supplied
      #
      # @example Find or initialize.
      #   person.posts.find_or_initialize_by(:title => "Test")
      #
      # @param [ Hash ] attrs The attributes to search or initialize with.
      # @param [ Class ] type The optional subclass to build.
      #
      # @return [ Document ] An existing document or newly instantiated one.
      def find_or_initialize_by(attrs = {}, type = nil, &block)
        find_or(:build, attrs, type, &block)
      end

      # This proxy can never be nil.
      #
      # @example Is the proxy nil?
      #   relation.nil?
      #
      # @return [ false ] Always false.
      def nil?
        false
      end

      # Since method_missing is overridden we should override this as well.
      #
      # @example Does the proxy respond to the method?
      #   relation.respond_to?(:name)
      #
      # @param [ Symbol ] name The method name.
      # @param [ true | false ] include_private Whether to include private methods.
      #
      # @return [ true | false ] If the proxy responds to the method.
      def respond_to?(name, include_private = false)
        [].respond_to?(name, include_private) ||
          klass.respond_to?(name, include_private) || super
      end

      # This is public access to the association's criteria.
      #
      # @example Get the scoped association.
      #   relation.scoped
      #
      # @return [ Criteria ] The scoped criteria.
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
      # @option options [ Symbol | String | Array<Symbol | String> ] :except Do not include these field(s).
      # @option options [ Symbol | String | Array<Symbol | String> ] :include Which association(s) to include.
      # @option options [ Symbol | String | Array<Symbol | String> ] :only Limit the field(s) to only these.
      #
      # @return [ Hash ] The documents, ready to be serialized.
      def serializable_hash(options = {})
        _target.map { |document| document.serializable_hash(options) }
      end

      # Get a criteria for the embedded documents without the default scoping
      # applied.
      #
      # @example Get the unscoped criteria.
      #   person.addresses.unscoped
      #
      # @return [ Criteria ] The unscoped criteria.
      def unscoped
        criteria.unscoped
      end

      # For compatibility with Rails' caching. Returns a string based on the
      # given timestamp, and includes the number of records in the relation
      # in the version.
      #
      # @param [ String | Symbol ] timestamp_column the timestamp column to
      #   use when constructing the key.
      #
      # @return [ String ] the cache version string
      def cache_version(timestamp_column = :updated_at)
        @cache_version ||= {}
        @cache_version[timestamp_column] ||= compute_cache_version(timestamp_column)
      end

      private

      def _session
        _base.send(:_session)
      end

      # Find the first object given the supplied attributes or create/initialize it.
      #
      # @example Find or create|initialize.
      #   person.addresses.find_or(:create, :street => "Bond")
      #
      #   @param [ Symbol ] method The method name, create or new.
      #   @param [ Hash ] attrs The attributes to search or build with.
      #   @param [ Class ] type The optional subclass to build.
      #
      # @return [ Document ] A matching document or a new/created one.
      def find_or(method, attrs = {}, type = nil, &block)
        attrs[klass.discriminator_key] = type.discriminator_value if type
        where(attrs).first || send(method, attrs, type, &block)
      end

      # Computes the cache version for the relation using the given
      # timestamp colum; see `#cache_version`.
      #
      # @param [ String | Symbol ] timestamp_column the timestamp column to
      #   use when constructing the key.
      #
      # @return [ String ] the cache version string
      def compute_cache_version(timestamp_column)
        timestamp_column = timestamp_column.to_s

        loaded = _target.respond_to?(:_loaded?) ?
                    _target._loaded? :   # has_many
                    true                 # embeds_many

        size, timestamp = loaded ?
          analyze_loaded_target(timestamp_column) :
          analyze_unloaded_target(timestamp_column)

        if timestamp
          "#{size}-#{timestamp.utc.to_formatted_s(klass.cache_timestamp_format)}"
        else
          size.to_s
        end
      end

      # Return a 2-tuple of the number of elements in the relation, and the
      # largest timestamp value.
      def analyze_loaded_target(timestamp_column)
        newest = _target.select { |elem| elem.respond_to?(timestamp_column) }
                        .max { |a, b| a[timestamp_column] <=> b[timestamp_column] }
        [ _target.length, newest ? newest[timestamp_column] : nil ]
      end

      # Returns a 2-tuple of the number of elements in the relation, and the
      # largest timestamp value. This will query the database to perform a
      # count and a max.
      def analyze_unloaded_target(timestamp_column)
        pipeline = criteria
          .group(_id: nil,
                 count: { '$count' => {} },
                 latest: { '$max' => "$#{timestamp_column}" })
          .pipeline

        result = klass.collection.aggregate(pipeline).to_a.first

        result ? [ result["count"], result["latest"] ] : [ 0 ]
      end
    end
  end
end
