# encoding: utf-8
module Mongoid
  module Relations

    # This class is the superclass for all relation proxy objects, and contains
    # common behaviour for all of them.
    class Proxy
      alias :extend_proxy :extend

      # We undefine most methods to get them sent through to the target.
      instance_methods.each do |method|
        undef_method(method) unless
          method =~ /(^__|^send|^object_id|^respond_to|^tap|extend_proxy)/
      end

      include Threaded::Lifecycle

      attr_accessor :base, :loaded, :metadata, :target

      # Backwards compatibility with Mongoid beta releases.
      delegate :klass, :foreign_key, :inverse_foreign_key, to: :metadata
      delegate :bind_one, :unbind_one, to: :binding
      delegate :collection_name, to: :base

      # Convenience for setting the target and the metadata properties since
      # all proxies will need to do this.
      #
      # @example Initialize the proxy.
      #   proxy.init(person, name, metadata)
      #
      # @param [ Document ] base The base document on the proxy.
      # @param [ Document, Array<Document> ] target The target of the proxy.
      # @param [ Metadata ] metadata The relation's metadata.
      #
      # @since 2.0.0.rc.1
      def init(base, target, metadata)
        @base, @target, @metadata = base, target, metadata
        yield(self) if block_given?
        extend_proxy(metadata.extension) if metadata.extension?
      end

      # The default substitutable object for a relation proxy is the clone of
      # the target.
      #
      # @example Get the substitutable.
      #   proxy.substitutable
      #
      # @return [ Object ] A clone of the target.
      #
      # @since 2.1.6
      def substitutable
        target
      end

      # Tell the next persistance operation to store in a specific collection,
      # database or session.
      #
      # @example Save the current document to a different collection.
      #   model.with(collection: "secondary").save
      #
      # @example Save the current document to a different database.
      #   model.with(database: "secondary").save
      #
      # @example Save the current document to a different session.
      #   model.with(session: "replica_set").save
      #
      # @example Save with a combination of options.
      #   model.with(session: "sharded", database: "secondary").save
      #
      # @param [ Hash ] options The storage options.
      #
      # @option options [ String, Symbol ] :collection The collection name.
      # @option options [ String, Symbol ] :database The database name.
      # @option options [ String, Symbol ] :session The session name.
      #
      # @return [ Document ] The current document.
      #
      # @since 3.0.0
      def with(options)
        Threaded.set_persistence_options(klass, options)
        self
      end

      protected

      # Get the collection from the root of the hierarchy.
      #
      # @example Get the collection.
      #   relation.collection
      #
      # @return [ Collection ] The root's collection.
      #
      # @since 2.0.0
      def collection
        root = base._root
        root.collection unless root.embedded?
      end

      # Takes the supplied document and sets the metadata on it.
      #
      # @example Set the metadata.
      #   proxt.characterize_one(name)
      #
      # @param [ Document ] document The document to set on.
      #
      # @since 2.0.0.rc.4
      def characterize_one(document)
        document.metadata = metadata unless document.metadata
      end

      # Default behavior of method missing should be to delegate all calls
      # to the target of the proxy. This can be overridden in special cases.
      #
      # @param [ String, Symbol ] name The name of the method.
      # @param [ Array ] *args The arguments passed to the method.
      def method_missing(name, *args, &block)
        target.send(name, *args, &block)
      end

      # When the base document illegally references an embedded document this
      # error will get raised.
      #
      # @example Raise the error.
      #   relation.raise_mixed
      #
      # @raise [ Errors::MixedRelations ] The error.
      #
      # @since 2.0.0
      def raise_mixed
        raise Errors::MixedRelations.new(base.class, metadata.klass)
      end

      # When the base is not yet saved and the user calls create or create!
      # on the relation, this error will get raised.
      #
      # @example Raise the error.
      #   relation.raise_unsaved(post)
      #
      # @param [ Document ] doc The child document getting created.
      #
      # @raise [ Errors::UnsavedDocument ] The error.
      #
      # @since 2.0.0.rc.6
      def raise_unsaved(doc)
        raise Errors::UnsavedDocument.new(base, doc)
      end

      class << self

        # Apply ordering to the criteria if it was defined on the relation.
        #
        # @example Apply the ordering.
        #   Proxy.apply_ordering(criteria, metadata)
        #
        # @param [ Criteria ] criteria The criteria to modify.
        # @param [ Metadata ] metadata The relation metadata.
        #
        # @return [ Criteria ] The ordered criteria.
        #
        # @since 3.0.6
        def apply_ordering(criteria, metadata)
          metadata.order ? criteria.order_by(metadata.order) : criteria
        end

        # Get the criteria that is used to eager load a relation of this
        # type.
        #
        # @example Get the eager load criteria.
        #   Proxy.eager_load(metadata, criteria)
        #
        # @param [ Metadata ] metadata The relation metadata.
        # @param [ Array<Object> ] ids The ids of the base docs.
        #
        # @return [ Criteria ] The criteria to eager load the relation.
        #
        # @since 2.2.0
        def eager_load_ids(metadata, ids)
          klass, foreign_key = metadata.klass, metadata.foreign_key
          eager_loaded = klass.any_in(foreign_key => ids).entries
          unless eager_loaded.empty?
            eager_loaded.each do |doc|
              base_id = doc.__send__(foreign_key)
              yield(doc, { foreign_key => base_id })
            end
          else
            ids.each do |id|
              IdentityMap.clear_many(klass, { foreign_key => id })
            end
          end
        end
      end
    end
  end
end
