# encoding: utf-8
module Mongoid

  # This module contains the behaviour of Mongoid's clone/dup of documents.
  module Copyable
    extend ActiveSupport::Concern

    COPYABLES = [
      :attributes,
      :metadata,
      :changed_attributes,
      :previous_changes
    ]

    protected

    # Clone or dup the current +Document+. This will return all attributes with
    # the exception of the document's id and versions, and will reset all the
    # instance variables.
    #
    # This clone also includes embedded documents.
    #
    # @example Clone the document.
    #   document.clone
    #
    # @example Dup the document.
    #   document.dup
    #
    # @param [ Document ] other The document getting cloned.
    #
    # @return [ Document ] The new document.
    def initialize_copy(other)
      other.as_document
      instance_variables.each { |name| remove_instance_variable(name) }
      COPYABLES.each do |name|
        value = other.send(name)
        instance_variable_set(:"@#{name}", value ? value.dup : nil)
      end
      attributes.delete("_id")
      if attributes.delete("versions")
        attributes["version"] = 1
      end
      @new_record = true
      apply_defaults
    end

    # @note Durran: Active Model introduced a change in 3.2.4 that requires
    #   this now from Mongoid's standpoint, otherwise their own internal
    #   definitiion gets called.
    alias :initialize_dup :initialize_copy
  end
end
