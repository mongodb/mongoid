# encoding: utf-8
module Mongoid #:nodoc:

  # Defines behaviour for the identity map in Mongoid.
  class IdentityMap < Hash

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
      return nil unless Mongoid.using_identity_map? && klass
      
      if identifier.is_a?(::Array)
        documents = documents_for(klass)
        return identifier.map{|id| documents[id] || (return nil) }
      end

      return documents_for(klass)[identifier] unless identifier.is_a?(Hash)

      return nil unless (map_ids = documents_for(klass)[identifier])

      return map_ids.map{|mid| documents_for(klass)[mid] } if map_ids.is_a?(Array)

      documents_for(klass)[map_ids]
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
      return nil unless Mongoid.using_identity_map? && document && document.id
      documents_for(document.class).delete(document.id)
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
      return nil unless Mongoid.using_identity_map? && document && document.id
      if (old_doc = documents_for(document.class)[document.id])
        log_reset_warning(old_doc, document)
        return old_doc
      end
      documents_for(document.class)[document.id] = document
    end

    # Logs a warning if an instance is set where it already existed.
    #
    # @example Log a warning.
    #   identity_map.log_reset_warning(old_doc, new_doc)
    #
    # @param [ Document ] document The old document.
    # @param [ Document ] document The new document.
    #
    # @since 3.?.?
    def log_reset_warning(old_doc, document)
      return unless Mongoid.logger
      warning = "MONGOID An attempt to reset the #{old_doc.class.name} instance #{old_doc.id} in the IdentityMap has been canceled. " +
                "Object_id new: #{document.object_id}, old: #{old_doc.object_id}."
      Mongoid.logger.warn(warning)
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
      (documents_for(document.class)[selector] ||= []).push(document.id)
      set(document)
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
      documents_for(document.class)[selector] = document.id
      set(document)
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
      return nil unless klass
      self[klass.collection_name] ||= {}
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
        { :to => :"Mongoid::Threaded.identity_map" }
      ))
    end
  end
end
