# frozen_string_literal: true

module Mongoid

  # This module handles reloading behavior of documents.
  module Reloadable

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
    def reload
      if @atomic_selector
        # Clear atomic_selector cache for sharded clusters. MONGOID-5076
        remove_instance_variable('@atomic_selector')
      end

      reloaded = _reload
      if Mongoid.raise_not_found_error && (reloaded.nil? || reloaded.empty?)
        raise Errors::DocumentNotFound.new(self.class, _id, _id)
      end
      @attributes = reloaded
      @attributes_before_type_cast = {}
      changed_attributes.clear
      reset_readonly
      apply_defaults
      reload_relations
      run_callbacks(:find) unless _find_callbacks.empty?
      run_callbacks(:initialize) unless _initialize_callbacks.empty?
      self
    end

    private

    # Reload the document, determining if it's embedded or not and what
    # behavior to use.
    #
    # @example Reload the document.
    #   document._reload
    #
    # @return [ Hash ] The reloaded attributes.
    def _reload
      embedded? ? reload_embedded_document : reload_root_document
    end

    # Reload the root document.
    #
    # @example Reload the document.
    #   document.reload_root_document
    #
    # @return [ Hash ] The reloaded attributes.
    def reload_root_document
      {}.merge(collection.find(atomic_selector, session: _session).read(mode: :primary).first || {})
    end

    # Reload the embedded document.
    #
    # @example Reload the document.
    #   document.reload_embedded_document
    #
    # @return [ Hash ] The reloaded attributes.
    def reload_embedded_document
      extract_embedded_attributes({}.merge(
        collection(_root).find(_root.atomic_selector, session: _session).read(mode: :primary).first
      ))
    end

    # Extract only the desired embedded document from the attributes.
    #
    # @example Extract the embedded document.
    #   document.extract_embedded_attributes(attributes)
    #
    # @param [ Hash ] attributes The document in the db.
    #
    # @return [ Hash | nil ] The document's extracted attributes or nil if the
    #   document doesn't exist.
    def extract_embedded_attributes(attributes)
      atomic_position.split(".").inject(attributes) do |attrs, part|
        attrs = attrs[part =~ /\d/ ? part.to_i : part]
        attrs
      end
    end
  end
end
