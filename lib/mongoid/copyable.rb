# encoding: utf-8
module Mongoid

  # This module contains the behaviour of Mongoid's clone/dup of documents.
  module Copyable
    extend ActiveSupport::Concern

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
    def clone
      attrs = as_document.except("_id")
      if attrs.delete("versions")
        attrs["version"] = 1
      end
      self.class.new(attrs, without_protection: true)
    end
    alias :dup :clone
  end
end
