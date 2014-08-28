# encoding: utf-8
module Mongoid

  # This module contains the behaviour of Mongoid's clone/dup of documents.
  module Copyable
    extend ActiveSupport::Concern

    # Clone or dup the current +Document+. This will return all attributes with
    # the exception of the document's id, and will reset all the
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
      attrs = clone_attr
      self.class.new(attrs)
    end
    alias :dup :clone

    private

    # Build a hash of attributes used for cloning
    # Includes embedded document attributes
    # Ignores dynamic attribtues
    #
    # @api private
    #
    # @example clone attr
    #   model.clone_attr
    #
    # @return [ Hash ] A hash with key/values used for cloning the document
    def clone_attr
      # @note This next line is here to address #2704, even though having an
      # _id and id field in the document would cause problems with Mongoid
      # elsewhere.
      attrs = clone_document.except("_id", "id")
      unless kind_of?(Mongoid::Attributes::Dynamic)      
        embedded_attrs = {}
        self.embedded_relations.keys.each do |relation_key|
          embedded_relation = [*self.send(self.embedded_relations[relation_key][:name])]
          embedded_attrs[relation_key] = embedded_relation.map do |relation|
            relation.send(:clone_attr)
          end
        end
        attrs.merge!(embedded_attrs)
        attrs = attrs.slice(*self.fields.keys, *self.embedded_relations.keys, *embedded_attrs.keys) 
      end
      attrs
    end

    # Clone the document attributes
    #
    # @api private
    #
    # @example clone document
    #   model.clone_document
    #
    # @param [ Hash ] dcoument The document with hash format
    #
    # @since 3.0.22
    def clone_document
      attrs = as_document.__deep_copy__
      process_localized_attributes(attrs)
      attrs
    end

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
