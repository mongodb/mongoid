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
      process_localized_attributes(attrs)
      self.class.new(attrs, without_protection: true)
    end
    alias :dup :clone

    private

    # When cloning, if the document has localized fields we need to ensure they
    # are properly processed in the clone.
    #
    # @api private
    #
    # @example Process localized attributes.
    #   model.process_localized_attributes(attributes)
    #
    # @param [ Hash ] attrs The attributes.
    #
    # @since 3.0.20
    def process_localized_attributes(attrs)
      localized_fields.keys.each do |name|
        if value = attrs.delete(name)
          attrs["#{name}_translations"] = value
        end
      end
    end
  end
end
