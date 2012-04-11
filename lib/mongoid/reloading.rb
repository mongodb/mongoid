# encoding: utf-8
module Mongoid #:nodoc:
  # This module handles reloading behaviour of documents.
  module Reloading

    # Reloads the +Document+ attributes from the database. If the document has
    # not been saved then an error will get raised if the configuration option
    # was set. This can reload root documents or embedded documents.
    #
    # @example Reload the document.
    #   person.reload
    #
    # @raise [ Errors::DocumentNotFound ] If the document was deleted.
    #
    # @return [ Document ] The document, reloaded.
    #
    # @since 1.0.0
    def reload
      reloaded = _reload
      if Mongoid.raise_not_found_error && reloaded.empty?
        raise Errors::DocumentNotFound.new(self.class, id, id)
      end
      @attributes = reloaded
      changed_attributes.clear
      apply_defaults
      reload_relations
      run_callbacks(:initialize)
      self
    end

    private

    # Reload the document, determining if it's embedded or not and what
    # behaviour to use.
    #
    # @example Reload the document.
    #   document._reload
    #
    # @return [ Hash ] The reloaded attributes.
    #
    # @since 2.3.2
    def _reload
      embedded? ? reload_embedded_document : reload_root_document
    end

    # Reload the root document.
    #
    # @example Reload the document.
    #   document.reload_root_document
    #
    # @return [ Hash ] The reloaded attributes.
    #
    # @since 2.3.2
    def reload_root_document
      {}.merge(collection.find(_id: id).one || {})
    end

    # Reload the embedded document.
    #
    # @example Reload the document.
    #   document.reload_embedded_document
    #
    # @return [ Hash ] The reloaded attributes.
    #
    # @since 2.3.2
    def reload_embedded_document
      extract_embedded_attributes({}.merge(
        _root.collection.find(_id: _root.id).one
      ))
    end

    # Extract only the desired embedded document from the attributes.
    #
    # @example Extract the embedded document.
    #   document.extract_embedded_attributes(attributes)
    #
    # @param [ Hash ] attributes The document in the db.
    #
    # @return [ Hash ] The document's extracted attributes.
    #
    # @since 2.3.2
    def extract_embedded_attributes(attributes)
      atomic_position.split(".").inject(attributes) do |attrs, part|
        attrs = attrs[part =~ /\d/ ? part.to_i : part]
        attrs
      end
    end
  end
end
