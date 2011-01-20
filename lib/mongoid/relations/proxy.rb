# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:

    # This class is the superclass for all relation proxy objects, and contains
    # common behaviour for all of them.
    class Proxy

      # We undefine most methods to get them sent through to the target.
      instance_methods.each do |method|
        undef_method(method) unless
          method =~ /(^__|^send$|^object_id$|^extend$|^tap$)/
      end

      attr_accessor :base, :loaded, :metadata, :target

      # Backwards compatibiloty with Mongoid beta releases.
      delegate :klass, :to => :metadata

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
      def init(base, target, metadata, &block)
        @base, @building, @target, @metadata = base, false, target, metadata
        yield block if block_given?
        extend Module.new(&metadata.extension) if metadata.extension?
      end

      protected

      # Yields to the block to allow the building flag to get set and unset for
      # the supplied code.
      #
      # @example Set the building status.
      #   person.building { @target << Post.new }
      #
      # @since 2.0.0.rc.1
      def building(&block)
        @building = true
        yield block if block_given?
        @building = false
      end

      # Convenience method for determining if we are building an association.
      # We never want to save in this case.
      #
      # @example Are we currently building?
      #   person.posts.building?
      #
      # @return [ true, false ] True if currently building, false if not.
      #
      # @since 2.0.0.rc.1
      def building?
        !!@building
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
        type ? type.instantiate : metadata.klass.instantiate
      end

      # Determines if the target been loaded into memory or not.
      #
      # @example Is the proxy loaded?
      #   proxy.loaded?
      #
      # @return [ true, false ] True if loaded, false if not.
      #
      # @since 2.0.0.rc.1
      def loaded?
        !!@loaded
      end

      # Takes the supplied documents and sets the metadata on them. Used when
      # creating new documents and adding them to the relation.
      #
      # @example Set the metadata.
      #   proxy.characterize(addresses)
      #
      # @param [ Array<Document> ] documents The documents to set metadata on.
      #
      # @since 2.0.0.rc.4
      def characterize(documents)
        documents.each { |doc| characterize_one(doc) }
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
    end
  end
end
