# frozen_string_literal: true

module Mongoid
  # Instantiates documents that came from the database.
  module Factory
    extend self

    # A helper class for instantiating a model using either it's type
    # class directly, or via a type class specified via a discriminator
    # key.
    #
    # @api private
    class Instantiator
      # @return [ Mongoid::Document ] The primary model class being referenced
      attr_reader :klass

      # @return [ Hash | nil ] The Hash of attributes to use when
      #   instantiating the model.
      attr_reader :attributes

      # @return [ Mongoid::Criteria | nil ] The criteria object to
      #   use as a secondary source for the selected fields; also used when
      #   setting the inverse association.
      attr_reader :criteria

      # @return [ Array | nil ] The list of field names that should
      #   be explicitly (and exclusively) included in the new record.
      attr_reader :selected_fields

      # @return [ String | nil ] The identifier of the class that
      #   should be loaded and instantiated, in the case of a polymorphic
      #   class specification.
      attr_reader :type

      # Creates a new Factory::Initiator.
      #
      # @param klass [ Mongoid::Document ] The primary class to reference when
      #   instantiating the model.
      # @param attributes [ Hash | nil ] (Optional) The hash of attributes to
      #   use when instantiating the model.
      # @param criteria [ Mongoid::Criteria | nil ] (Optional) The criteria
      #   object to use as a secondary source for the selected fields; also
      #   used when setting the inverse association.
      # @param selected_fields [ Array | nil ] The list of field names that
      #   should be explicitly (and exclusively) included in the new record.
      def initialize(klass, attributes, criteria, selected_fields)
        @klass = klass
        @attributes = attributes
        @criteria = criteria
        @selected_fields = selected_fields ||
                           (criteria && criteria.options[:fields])
        @type = attributes && attributes[klass.discriminator_key]
      end

      # Builds and returns a new instance of the requested class.
      #
      # @param execute_callbacks [ true | false ] Whether or not the Document
      #   callbacks should be invoked with the new instance.
      #
      # @raise [ Errors::UnknownModel ] when the requested type does not exist,
      #   or if it does not respond to the `instantiate` method.
      #
      # @return [ Mongoid::Document ] The new document instance.
      def instance(execute_callbacks: Threaded.execute_callbacks?)
        if type.blank?
          instantiate_without_type(execute_callbacks)
        else
          instantiate_with_type(execute_callbacks)
        end
      end

      private

      # Instantiate the given class without any given subclass.
      #
      # @param [ true | false ] execute_callbacks Whether this method should
      #   invoke document callbacks.
      #
      # @return [ Document ] The instantiated document.
      def instantiate_without_type(execute_callbacks)
        klass.instantiate_document(attributes, selected_fields, execute_callbacks: execute_callbacks).tap do |obj|
          if criteria&.association && criteria&.parent_document
            obj.set_relation(criteria.association.inverse, criteria.parent_document)
          end
        end
      end

      # Instantiate the given `type`, which must map to another Mongoid::Document
      # model.
      #
      # @param [ true | false ] execute_callbacks Whether this method should
      #   invoke document callbacks.
      #
      # @return [ Document ] The instantiated document.
      def instantiate_with_type(execute_callbacks)
        constantized_type.instantiate_document(
          attributes, selected_fields,
          execute_callbacks: execute_callbacks
        )
      end

      # Retreive the `Class` instance of the requested type, either by finding it
      # in the `klass` discriminator mapping, or by otherwise finding a
      # Document model with the given name.
      #
      # @return [ Mongoid::Document ] the requested Document model
      def constantized_type
        @constantized_type ||= begin
          constantized = klass.get_discriminator_mapping(type) || constantize(type)

          # Check if the class is a Document class
          raise Errors::UnknownModel.new(camelized, type) unless constantized.respond_to?(:instantiate)

          constantized
        end
      end

      # Attempts to convert the argument into a Class object by camelizing
      # it and treating the result as the name of a constant.
      #
      # @param type [ String ] The name of the type to constantize
      #
      # @raise [ Errors::UnknownModel ] if the argument does not correspond to
      #   an existing constant.
      #
      # @return [ Class ] the Class that the type resolves to
      def constantize(type)
        camelized = type.camelize
        camelized.constantize
      rescue NameError
        raise Errors::UnknownModel.new(camelized, type)
      end
    end

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
    #
    # @option options [ true | false ] :execute_callbacks Flag specifies whether callbacks
    #   should be run.
    #
    # @return [ Document ] The instantiated document.
    def build(klass, attributes = nil)
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
    def execute_from_db(klass, attributes = nil, criteria = nil,
                        selected_fields = nil,
                        execute_callbacks: Threaded.execute_callbacks?)
      Instantiator.new(klass, attributes, criteria, selected_fields)
                  .instance(execute_callbacks: execute_callbacks)
    end
  end
end
