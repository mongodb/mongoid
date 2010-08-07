# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    class Proxy #:nodoc

      instance_methods.each do |method|
        undef_method(method) unless method =~ /(^__|^send$|^object_id$|^extend$)/
      end

      attr_accessor \
        :base,
        :metadata,
        :target

      protected

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
      def init(base, target, metadata)
        @base, @target, @metadata = base, target, metadata
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
        @target.send(name, *args, &block)
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
    end
  end
end
