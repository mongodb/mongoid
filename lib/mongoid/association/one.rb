# frozen_string_literal: true
# encoding: utf-8

module Mongoid
  module Association

    # This is the superclass for one to one relations and defines the common
    # behavior or those proxies.
    class One < Association::Proxy

      # Clear this relation - same as calling #delete on the document.
      #
      # @example Clear the relation.
      #   relation.clear
      #
      # @return [ true, false ] If the delete suceeded.
      #
      # @since 3.0.0
      def clear
        _target.delete
      end

      # Get all the documents in the relation that are loaded into memory.
      #
      # @example Get the in memory documents.
      #   relation.in_memory
      #
      # @return [ Array<Document> ] The documents in memory.
      #
      # @since 2.1.0
      def in_memory
        [ _target ]
      end

      # Since method_missing is overridden we should override this as well.
      #
      # @example Does the proxy respond to the method?
      #   relation.respond_to?(:name)
      #
      # @param [ Symbol ] name The method name.
      #
      # @return [ true, false ] If the proxy responds to the method.
      #
      # @since 2.1.8
      def respond_to?(name, include_private = false)
        _target.respond_to?(name, include_private) || super
      end

      # Evolve the proxy document into an object id.
      #
      # @example Evolve the proxy document.
      #   proxy.__evolve_object_id__
      #
      # @return [ Object ] The proxy document's id.
      #
      # @since 4.0.0
      def __evolve_object_id__
        _target._id
      end
    end
  end
end
