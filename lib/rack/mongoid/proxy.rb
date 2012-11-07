# encoding: utf-8
module Rack
  module Mongoid

    # Override the Rack::BodyProxy to ensure that our passed block gets
    # executed even when exceptions are raised.
    class Proxy < Rack::BodyProxy

      # Rack's implementation of this method ensures that the block is called
      # here, but in the case of an error close might not get called. We remove
      # the block call here.
      #
      # @example Close the body.
      #   proxy.close
      #
      # @return [ Object ] The result of the body close.
      #
      # @since 3.0.12
      def close
        return if @closed
        @closed = true
        @body.close if @body.respond_to?(:close)
      end

      # We ensure here that the block is called that we passed to the
      # constructor unless the body is already closed.
      #
      # @param [ Array<Object ] args The arguments for each.
      #
      # @return [ Object ] The result of body.each.
      #
      # @since 3.0.12
      def each(*args, &block)
        @body.each(*args, &block)
      ensure
        unless @closed
          @closed = true
          @block.call
        end
      end
    end
  end
end
