# encoding: utf-8
module Mongoid #:nodoc:

  # Defines behaviour for the identity map in Mongoid.
  class IdentityMap < Hash

    # Get a document from the identity map by its id.
    #
    # @param [ Object ] id The document id.
    #
    # @return [ Document ] The matching document.
    #
    # @since 2.1.0
    def get(id)
      self[id]
    end

    # Puts a document in the identity map, accessed by it's id.
    #
    # @example Put the document in the map.
    #   identity_map.set(document)
    #
    # @param [ Document ] document The document to place in the map.
    #
    # @return [ Document ] The provided document.
    #
    # @since 2.1.0
    def set(document)
      return unless document
      self[document.id] = document
    end

    class << self

      # For ease of access we provide the same API to the identity map on the
      # class level, which in turn just gets the identity map that is on the
      # current thread.
      #
      # @example Get a document from the current identity map by id.
      #   IdentityMap.get(id)
      #
      # @example Set a document in the current identity map.
      #   IdentityMap.set(document)
      #
      # @since 2.1.0
      delegate *(
        Hash.public_instance_methods(false) +
        IdentityMap.public_instance_methods(false) <<
        { :to => :"Mongoid::Threaded.identity_map" }
      )
    end
  end
end
