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

    # Get multiple documents matching the provided ids.
    #
    # @param [ Array<Object> ] ids The document ids.
    #
    # @return [ Array<Document> ] The matching documents.
    #
    # @since 2.1.0
    def get_multi(ids)
      matching = ids.inject([]) do |documents, id|
        documents.tap do |docs|
          matching = self[id]
          docs.push(matching) if matching
        end
      end
      matching.empty? ? nil : matching
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

    # Puts multiple documents in the identity map.
    #
    # @example Put multiple documents in the map.
    #   identity_map.set_multi([ document_one, document_two ])
    #
    # @param [ Array<Document> ] documents The documents to set.
    #
    # @return [ Array<Document>, nil ] The documents inserted.
    #
    # @since 2.1.0
    def set_multi(documents)
      return if documents.blank?
      documents.map { |doc| self[doc.id] = doc }
    end

    class << self

      # For ease of access we provide the same API to the identity map on the
      # class level, which in turn just gets the identity map that is on the
      # current thread.
      #
      # @example Get a document from the current identity map by id.
      #   IdentityMap.get(id)
      #
      # @example Get documents from the current identity map by ids.
      #   IdentityMap.get_multi([ id_one, id_two ])
      #
      # @example Set a document in the current identity map.
      #   IdentityMap.set(document)
      #
      # @example Set multiple documents in the identity map
      #   IdentityMap.set_multi([ doc_one, doc_two ])
      #
      # @since 2.1.0
      delegate :clear, :get, :get_multi, :set, :set_multi,
        :to => :"Mongoid::Threaded.identity_map"
    end
  end
end
