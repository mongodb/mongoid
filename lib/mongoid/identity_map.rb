# encoding: utf-8
module Mongoid

  # Defines behaviour for the identity map in Mongoid.
  class IdentityMap < Hash

    # Clear out the loaded documents for the provided selector.
    #
    # @example Clear out the documents.
    #   map.clear_many(Post, { person_id: person.id })
    #
    # @param [ Class ] klass The class of the relation.
    # @param [ Hash ] selector The selector.
    #
    # @return [ Array ] An empty array.
    #
    # @since 2.4.10
    def clear_many(klass, selector)
      documents_for(klass)[selector] = {}
    end

    # Get a document from the identity map by its id.
    #
    # @example Get the document from the map.
    #   map.get(Person, id)
    #
    # @param [ Class ] klass The class of the document.
    # @param [ Object, Hash ] idenfier The document id or selector.
    #
    # @return [ Document ] The matching document.
    #
    # @since 2.1.0
    def get(klass, identifier)
      if Mongoid.using_identity_map? && klass
        if identifier.is_a?(::Array)
          documents = documents_for(klass)
          identifier.map do |id|
            documents[id] || (return nil)
          end
        else
          documents_for(klass)[identifier]
        end
      end
    end

    # Get many documents from the map via the selector
    #
    # @example Get the document from the map.
    #   map.get(Person, { post_id: post })
    #
    # @param [ Class ] klass The class of the document.
    # @param [ Hash ] idenfier The selector.
    #
    # @return [ Array<Document> ] The matching documents.
    #
    # @since 3.0.0
    def get_many(klass, identifier)
      if Mongoid.using_identity_map? && klass
        documents_for(klass)[identifier].try(:values)
      end
    end

    # Remove the document from the identity map.
    #
    # @example Remove the document.
    #   map.removed(person)
    #
    # @param [ Document ] document The document to remove.
    #
    # @return [ Document, nil ] The removed document.
    #
    # @since 2.1.0
    def remove(document)
      if Mongoid.using_identity_map? && document && document.id
        documents_for(document.class).delete(document.id)
      end
    end

    # Puts a document in the identity map, accessed by its id.
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
      if Mongoid.using_identity_map? && document && document.id
        documents_for(document.class)[document.id] = document
      end
    end

    # Set a document in the identity map for the provided selector.
    #
    # @example Set the document in the map.
    #   identity_map.set_selector(document, { :person_id => person.id })
    #
    # @param [ Document ] document The document to set.
    # @param [ Hash ] selector The selector to identify it.
    #
    # @return [ Array<Document> ] The documents.
    #
    # @since 2.2.0
    def set_many(document, selector)
      (documents_for(document.class)[selector] ||= {})[document.id] = document
    end

    # Set a document in the identity map for the provided selector.
    #
    # @example Set the document in the map.
    #   identity_map.set_selector(document, { :person_id => person.id })
    #
    # @param [ Document ] document The document to set.
    # @param [ Hash ] selector The selector to identify it.
    #
    # @return [ Document ] The matching document.
    #
    # @since 2.2.0
    def set_one(document, selector)
      documents_for(document.class)[selector] = document
    end

    private

    # Get the documents in the identity map for a specific class.
    #
    # @example Get the documents for the class.
    #   map.documents_for(Person)
    #
    # @param [ Class ] klass The class to retrieve.
    #
    # @return [ Hash ] The documents.
    #
    # @since 2.1.0
    def documents_for(klass)
      if klass
        self[klass.collection_name] ||= {}
      end
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
      delegate(*(
        Hash.public_instance_methods(false) +
        IdentityMap.public_instance_methods(false) <<
        { to: :"Mongoid::Threaded.identity_map" }
      ))
    end
  end
end
