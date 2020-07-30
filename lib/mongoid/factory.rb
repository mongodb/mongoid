# frozen_string_literal: true
# encoding: utf-8

module Mongoid

  # Instantiates documents that came from the database.
  module Factory
    extend self

    # @deprecated
    TYPE = "_type".freeze

    # Builds a new +Document+ from the supplied attributes.
    #
    # This method either instantiats klass or a descendant of klass if the attributes include
    # klass' discriminator key.
    #
    # If the attributes contain the discriminator key (which is _type by default) and the
    # discriminator value does not correspond to a descendant of klass then this method
    # would create an instance of klass.
    #
    # @example Build the document.
    #   Mongoid::Factory.build(Person, { "name" => "Durran" })
    #
    # @param [ Class ] klass The class to instantiate from if _type is not present.
    # @param [ Hash ] attributes The document attributes.
    #
    # @return [ Document ] The instantiated document.
    def build(klass, attributes = nil)
      attributes ||= {}
      dvalue = attributes[klass.discriminator_key] || attributes[klass.discriminator_key.to_sym]
      type = klass.get_discriminator_mapping(dvalue)
      if type
        type.new(attributes)
      else
        klass.new(attributes)
      end
    end

    # Builds a new +Document+ from the supplied attributes loaded from the
    # database.
    #
    # If the attributes contain the discriminator key (which is _type by default) and the
    # discriminator value does not correspond to a descendant of klass then this method
    # raises an UnknownModel error.
    #
    # If a criteria object is given, it is used in two ways:
    # 1. If the criteria has a list of fields specified via #only,
    #    only those fields are populated in the returned document.
    # 2. If the criteria has a referencing association (i.e., this document
    #    is being instantiated as an association of another document),
    #    the other document is also populated in the returned document's
    #    reverse association, if one exists.
    #
    # @example Build the document.
    #   Mongoid::Factory.from_db(Person, { "name" => "Durran" })
    #
    # @param [ Class ] klass The class to instantiate from if _type is not present.
    # @param [ Hash ] attributes The document attributes.
    # @param [ Criteria ] criteria Optional criteria object.
    # @param [ Hash ] selected_fields Fields which were retrieved via
    #   #only. If selected_fields are specified, fields not listed in it
    #   will not be accessible in the returned document.
    #
    # @return [ Document ] The instantiated document.
    def from_db(klass, attributes = nil, criteria = nil, selected_fields = nil)
      if criteria
        selected_fields ||= criteria.options[:fields]
      end
      type = (attributes || {})[klass.discriminator_key]
      if type.blank?
        obj = klass.instantiate(attributes, selected_fields)
        if criteria && criteria.association && criteria.parent_document
          obj.set_relation(criteria.association.inverse, criteria.parent_document)
        end
        obj
      else
        constantized = klass.get_discriminator_mapping(type)

        unless constantized
          camelized = type.camelize

          # Check if the class exists
          begin
            constantized = camelized.constantize
          rescue NameError
            raise Errors::UnknownModel.new(camelized, type)
          end
        end

        # Check if the class is a Document class
        if !constantized.respond_to?(:instantiate)
          raise Errors::UnknownModel.new(camelized, type)
        end

        constantized.instantiate(attributes, selected_fields)
      end
    end
  end
end
