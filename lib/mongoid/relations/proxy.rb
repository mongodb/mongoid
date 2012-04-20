# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:

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
      delegate :klass, :to => :metadata
      delegate :bind_one, :unbind_one, :to => :binding
      delegate :collection_name, :to => :base

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

      # Return a new document for the type of class we want to instantiate.
      # If the type is provided use that, otherwise the klass from the
      # metadata.
      #
      # @example Get an instantiated document.
      #   proxy.instantiated(Person)
      #
      # @param [ Class ] type The type of class to instantiate.
      #
      # @return [ Document ] The freshly created document.
      #
      # @since 2.0.0.rc.1
      def instantiated(type = nil)
        type ? type.new : metadata.klass.new
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

      # Get the class of the root document in the hierarchy.
      #
      # @example Get the root's class.
      #   proxy.root_class
      #
      # @return [ Class ] The root class.
      #
      # @since 2.1.8
      def root_class
        @root_class ||= base._root.class
      end
    end
  end
end
