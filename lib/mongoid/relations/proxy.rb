# encoding: utf-8
module Mongoid # :nodoc:
  module Relations #:nodoc:
    class Proxy #:nodoc
      attr_reader \
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
      def init(target, metadata)
        @target, @metadata = target, metadata
      end
    end
  end
end
