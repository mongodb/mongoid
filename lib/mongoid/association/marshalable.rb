# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Association
    module Marshalable

      # Provides the data needed to Marshal.dump an association proxy.
      #
      # @example Dump the proxy.
      #   Marshal.dump(proxy)
      #
      # @return [ Array<Object> ] The dumped data.
      #
      # @since 3.0.15
      def marshal_dump
        [ _base, _target, _association ]
      end

      # Takes the provided data and sets it back on the proxy.
      #
      # @example Load the proxy.
      #   Marshal.load(proxy)
      #
      # @param [ Array<Object> ] data The data to set on the proxy.
      #
      # @return [ Array<Object> ] The loaded data.
      #
      # @since 3.0.15
      def marshal_load(data)
        @_base, @_target, @_association = data
        extend_proxy(_association.extension) if _association.extension
      end
    end
  end
end
