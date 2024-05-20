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
      reloaded = _reload
      check_for_deleted_document!(reloaded)

      reset_object!(reloaded)

      run_callbacks(:find) unless _find_callbacks.empty?
      run_callbacks(:initialize) unless _initialize_callbacks.empty?
      self
    end

    private

    # Resets the current object using the given attributes.
    #
    # @param [ Hash ] attributes The attributes to use to replace the current
    #   attributes hash.
    def reset_object!(attributes)
      reset_atomic_updates!

      @attributes = attributes
      @attributes_before_type_cast = @attributes.dup
      @changed_attributes = {}
      @previous_changes = {}
      @previous_attributes = {}
      @previously_new_record = false

      reset_readonly
      apply_defaults
      reload_relations
    end

    # Checks to see if the given attributes argument indicates that the object
    # has been deleted. If the attributes are nil or an empty Hash, then
    # we assume it has been deleted.
    #
    # If Mongoid.raise_not_found_error is false, this will do nothing.
    #
    # @param [ Hash | nil ] attributes The attributes hash retrieved from
    #   the database
    #
    # @raise [ Errors::DocumentNotFound ] If the document was deleted.
    def check_for_deleted_document!(attributes)
      return unless Mongoid.raise_not_found_error
      return unless attributes.nil? || attributes.empty?

      shard_keys = atomic_selector.with_indifferent_access.slice(*shard_key_fields, :_id)
      raise Errors::DocumentNotFound.new(self.class, _id, shard_keys)
    end

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
      Mongoid::Attributes::Embedded.traverse(
        collection(_root).find(_root.atomic_selector, session: _session).read(mode: :primary).first,
        atomic_position
      )
    end
  end
end
