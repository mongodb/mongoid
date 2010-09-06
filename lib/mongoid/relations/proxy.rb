# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    class Proxy #:nodoc

      instance_methods.each do |method|
        undef_method(method) unless
          method =~ /(^__|^send$|^object_id$|^extend$|^tap$)/
      end

      attr_accessor \
        :base,
        :metadata,
        :target

      protected

      # Yields to the block to allow the building flag to get set and unset for
      # the supplied code.
      #
      # Example:
      #
      # <tt>person.building { @target << Post.new }</tt>
      #
      # Options:
      #
      # block: The block to have the building flag set around.
      def building(&block)
        @building = true
        yield block if block_given?
        @building = false
      end

      # Convenience method for determining if we are building an association.
      # We never want to save in this case.
      #
      # Example:
      #
      # <tt>person.posts.building?</tt>
      #
      # Returns:
      #
      # true if currently building, false if not.
      def building?
        !!@building
      end

      # Convenience for setting the target and the metadata properties since
      # all proxies will need to do this.
      #
      # Example:
      #
      # <tt>proxy.init(target, metadata)<tt>
      #
      # Options:
      #
      # target: The target of the proxy.
      # metadata: The relation's metadata.
      def init(base, target, metadata, &block)
        @base, @building, @target, @metadata = base, false, target, metadata
        metadatafy(target)
        yield block if block_given?
        extend Module.new(&metadata.extension) if metadata.extension?
      end

      # Return a new document for the type of class we want to instantiate.
      # If the type is provided use that, otherwise the klass from the
      # metadata.
      #
      # Options:
      #
      # type: The type of class to instantiate.
      #
      # Returns:
      #
      # A +Document+
      def instantiated(type = nil)
        type ? type.instantiate : @metadata.klass.instantiate
      end

      def loaded?
        !target.is_a?(Mongoid::Criteria)
      end

      def metadatafy(object)
        object.to_a.each { |obj| obj.metadata = metadata }
      end

      # Default behavior of method missing should be to delegate all calls
      # to the target of the proxy. This can be overridden in special cases.
      #
      # Options:
      #
      # name: The name of the method.
      # args: The arguments passed to the method.
      # block: Optional block to pass.
      def method_missing(name, *args, &block)
        target.send(name, *args, &block)
      end
    end
  end
end
