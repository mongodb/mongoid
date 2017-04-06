# encoding: utf-8
module Mongoid
  module Associations
    module Marshalable

      # Provides the data needed to Marshal.dump a relation proxy.
      #
      # @example Dump the proxy.
      #   Marshal.dump(proxy)
      #
      # @return [ Array<Object> ] The dumped data.
      #
      # @since 3.0.15
      def marshal_dump
        [ base, target, __association ]
      end

      # Takes the provided data and sets it back on the proxy.
      #
      # @example Load the proxy.
      #   Marshal.load(proxy)
      #
      # @return [ Array<Object> ] The loaded data.
      #
      # @since 3.0.15
      def marshal_load(data)
        @base, @target, @__association = data
        extend_proxy(__association.extension) if __association.extension
      end
    end
  end
end
