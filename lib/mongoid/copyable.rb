# encoding: utf-8
module Mongoid #:nodoc:

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
    # @param [ Document ] other The document getting cloned.
    #
    # @return [ Document ] The new document.
    def initialize_copy(other)
      __copy__(other)
    end

    # Clone or dup the current +Document+. This will return all attributes with
    # the exception of the document's id and versions, and will reset all the
    # instance variables.
    #
    # This clone also includes embedded documents.
    #
    # @example Dup the document.
    #   document.dup
    #
    # @param [ Document ] other The document getting cloned.
    #
    # @return [ Document ] The new document.
    def initialize_dup(other)
      __copy__(other)
    end

    private

    # Handle the copy of the object.
    #
    # @api private
    #
    # @example Copy the object.
    #   document.__copy__(other)
    #
    # @param [ Document ] other The other document.
    #
    # @return [ Document ] self.
    #
    # @since 3.0.0
    def __copy__(other)
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
      identify
    end
  end
end
