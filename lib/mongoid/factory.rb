# frozen_string_literal: true

module Mongoid

  # Instantiates documents that came from the database.
  module Factory
    extend self

    # Builds a new +Document+ from the supplied attributes.
    #
    # This method either instantiates klass or a descendant of klass if the attributes include
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
    # @param [ true | false ] execute_callbacks Flag specifies whether callbacks
    #   should be run.
    #
    # @return [ Document ] The instantiated document.
    def build(klass, attributes = nil)
      # A bug in Ruby 2.x (including 2.7.7) causes the attributes hash to be
      # interpreted as keyword arguments, because execute_build accepts
      # a keyword argument. Forcing an empty set of keyword arguments works
      # around the bug. Once Ruby 2.x support is dropped, this hack can be
      # removed.
      # See https://bugs.ruby-lang.org/issues/15753
      execute_build(klass, attributes)
    end

    # Execute the build.
    #
    # @param [ Class ] klass The class to instantiate from if _type is not present.
    # @param [ Hash ] attributes The document attributes.
    # @param [ Hash ] options The options to use.
    #
    # @option options [ true | false ] :execute_callbacks Flag specifies
    #   whether callbacks should be run.
    #
    # @note A Ruby 2.x bug prevents the options hash from being keyword
    #   arguments. Once we drop support for Ruby 2.x, we can reimplement
    #   the options hash as keyword arguments.
    #   See https://bugs.ruby-lang.org/issues/15753
    #
    # @return [ Document ] The instantiated document.
    #
    # @api private
    def execute_build(klass, attributes = nil, options = {})
      attributes ||= {}
      dvalue = attributes[klass.discriminator_key] || attributes[klass.discriminator_key.to_sym]
      type = klass.get_discriminator_mapping(dvalue)
      if type
        type.construct_document(attributes, options)
      else
        klass.construct_document(attributes, options)
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
      execute_from_db(klass, attributes, criteria, selected_fields)
    end

    # Execute from_db.
    #
    # @param [ Class ] klass The class to instantiate from if _type is not present.
    # @param [ Hash ] attributes The document attributes.
    # @param [ Criteria ] criteria Optional criteria object.
    # @param [ Hash ] selected_fields Fields which were retrieved via
    #   #only. If selected_fields are specified, fields not listed in it
    #   will not be accessible in the returned document.
    # @param [ true | false ] execute_callbacks Whether this method should
    #   invoke the callbacks. If true, the callbacks will be invoked normally.
    #   If false, the callbacks will be stored in the +pending_callbacks+ list
    #   and caller is responsible for invoking +run_pending_callbacks+ at a
    #   later time. Use this option to defer callback execution until the
    #   entire object graph containing embedded associations is constructed.
    #
    # @return [ Document ] The instantiated document.
    #
    # @api private
    def execute_from_db(klass, attributes = nil, criteria = nil, selected_fields = nil, execute_callbacks: Threaded.execute_callbacks?)
      if criteria
        selected_fields ||= criteria.options[:fields]
      end
      type = (attributes || {})[klass.discriminator_key]
      if type.blank?
        obj = klass.instantiate_document(attributes, selected_fields, execute_callbacks: execute_callbacks)
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

        constantized.instantiate_document(attributes, selected_fields, execute_callbacks: execute_callbacks)
      end
    end
  end
end
