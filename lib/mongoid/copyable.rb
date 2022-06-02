# frozen_string_literal: true

module Mongoid

  # This module contains the behavior of Mongoid's clone/dup of documents.
  module Copyable
    extend ActiveSupport::Concern

    # Clone or dup the current +Document+. This will return all attributes with
    # the exception of the document's id, and will reset all the
    # instance variables.
    #
    # This clone also includes embedded documents. If there is an _id field in
    # the embedded document, it will be maintained, unlike the root's _id.
    #
    # If cloning an embedded child, the embedded parent is not cloned and the
    # embedded_in association is not set.
    #
    # @example Clone the document.
    #   document.clone
    #
    # @return [ Document ] The new document.
    def clone
      # @note This next line is here to address #2704, even though having an
      # _id and id field in the document would cause problems with Mongoid
      # elsewhere. Note this is only done on the root document as we want
      # to maintain the same _id on the embedded documents.
      attrs = clone_document.except(*self.class.id_fields)
      Copyable.clone_with_hash(self.class, attrs)
    end
    alias :dup :clone

    private

    # Create clone of a document of the given klass with the given attributes
    # hash. This is used recursively so that embedded associations are cloned
    # safely.
    #
    # @param klass [ Class ] The class of the document to create.
    # @param attrs [ Hash ] The hash of the attributes.
    #
    # @return [ Document ] The new document.
    def self.clone_with_hash(klass, attrs)
      dynamic_attrs = {}
      _attribute_names = klass.attribute_names
      attrs.reject! do |attr_name, value|
        unless _attribute_names.include?(attr_name)
          dynamic_attrs[attr_name] = value
          true
        end
      end

      Factory.build(klass, attrs).tap do |object|
        dynamic_attrs.each do |attr_name, value|
          assoc = object.embedded_relations[attr_name]
          if assoc&.one? && Hash === value
            object.send("#{attr_name}=", clone_with_hash(assoc.klass, value))
          elsif assoc&.many? && Array === value
            docs = value.map { |h| clone_with_hash(assoc.klass, h) }
            object.send("#{attr_name}=", docs)
          elsif object.respond_to?("#{attr_name}=")
            object.send("#{attr_name}=", value)
          else
            object.attributes[attr_name] = value
          end
        end
      end
    end

    # Clone the document attributes
    #
    # @api private
    #
    # @example clone document
    #   model.clone_document
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
            embedded_klass = if type = attr[self.class.discriminator_key]
              association.relation_class.get_discriminator_mapping(type) || association.relation_class
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
