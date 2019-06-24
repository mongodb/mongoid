# frozen_string_literal: true
# encoding: utf-8

module Mongoid

  # This module contains the behavior of Mongoid's clone/dup of documents.
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
    # @return [ Document ] The new document.
    def clone
      # @note This next line is here to address #2704, even though having an
      # _id and id field in the document would cause problems with Mongoid
      # elsewhere.
      attrs = clone_document.except("_id", "id")
      dynamic_attrs = {}
      attrs.reject! do |attr_name, value|
        dynamic_attrs.merge!(attr_name => value) unless self.attribute_names.include?(attr_name)
      end
      self.class.new(attrs).tap do |object|
        dynamic_attrs.each do |attr_name, value|
          if object.respond_to?("#{attr_name}=")
            object.send("#{attr_name}=", value)
          else
            object.attributes[attr_name] = value
          end
        end
      end
    end
    alias :dup :clone

    private

    # Clone the document attributes
    #
    # @api private
    #
    # @example clone document
    #   model.clone_document
    #
    # @since 3.0.22
    def clone_document
      attrs = as_attributes.__deep_copy__
      process_localized_attributes(self, attrs)
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
    def process_localized_attributes(klass, attrs)
      klass.localized_fields.keys.each do |name|
        if value = attrs.delete(name)
          attrs["#{name}_translations"] = value
        end
      end
      klass.embedded_relations.each do |_, association|
        next unless attrs.present? && attrs[association.key].present?

        if association.is_a?(Association::Embedded::EmbedsMany)
          attrs[association.key].each do |attr|
            embedded_klass = if type = attr['_type']
              type.constantize
            else
              association.relation_class
            end
            process_localized_attributes(embedded_klass, attr)
          end
        else
          process_localized_attributes(association.klass, attrs[association.key])
        end
      end
    end
  end
end
