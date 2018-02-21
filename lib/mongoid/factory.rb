# encoding: utf-8
module Mongoid

  # Instantiates documents that came from the database.
  module Factory
    extend self

    TYPE = "_type".freeze

    # Builds a new +Document+ from the supplied attributes.
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
      type = attributes[TYPE] || attributes[TYPE.to_sym]
      if type && klass._types.include?(type)
        type.constantize.new(attributes)
      else
        klass.new(attributes)
      end
    end

    # Builds a new +Document+ from the supplied attributes loaded from the
    # database.
    #
    # @example Build the document.
    #   Mongoid::Factory.from_db(Person, { "name" => "Durran" })
    #
    # @param [ Class ] klass The class to instantiate from if _type is not present.
    # @param [ Hash ] attributes The document attributes.
    # @param [ Array ] selected_fields If instantiated from a criteria using
    #   #only we give the document a list of the selected fields.
    #
    # @return [ Document ] The instantiated document.
    def from_db(klass, attributes = nil, criteria = nil)
      selected_fields = criteria.options[:fields] if criteria
      type = (attributes || {})[TYPE]
      if type.blank?
        obj = klass.instantiate(attributes, selected_fields)
        if criteria && criteria.association && criteria.parent_document
          obj.set_relation(criteria.association.inverse, criteria.parent_document)
        end
        obj
      else
        camelized = type.camelize
        begin
          camelized.constantize.instantiate(attributes, selected_fields)
        rescue NameError
          raise Errors::UnknownModel.new(camelized, type)
        end
      end
    end
  end
end
