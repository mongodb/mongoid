# frozen_string_literal: true
# rubocop:todo all

require 'mongoid/extensions/boolean'
require 'mongoid/stringified_symbol'

module Mongoid
  module Config
    # This module contains the logic for configuring Client Side
    # Field Level automatic encryption.
    #
    # @api private
    module Encryption
      extend self

      # Generate the encryption schema map for the provided models.
      #
      # @param [ String ] default_database The default database name.
      # @param [ Array<Mongoid::Document> ] models The models to generate the schema map for.
      #   Defaults to all models in the application.
      #
      # @return [ Hash ] The encryption schema map.
      def encryption_schema_map(default_database, models = ::Mongoid.models)
        models.each_with_object({}) do |model, map|
          next if model.embedded?
          next unless model.requires_encryption_schema?

          database = model.storage_options.fetch(:database) { default_database }
          # A callable database name cannot be resolved here: the documented
          # multi-tenant idiom has no correct value while the client is being
          # built. Interpolating the callable would produce a key that never
          # matches any namespace, so leave the model out of the map. Writes
          # are refused later, by PersistenceContext, rather than silently
          # going out unencrypted.
          next if database.respond_to?(:call)

          key = "#{database}.#{model.collection_name}"
          props = metadata_for(model).merge(properties_for(model, [ model ]))
          # The root of a collection schema describes the document, so it is
          # always an object. Saying so matters when a nested schema carries
          # encryptMetadata: mongocryptd rejects the schema otherwise.
          map[key] = { 'bsonType' => 'object' }.merge(props) unless props.empty?
        end
      end

      private

      # The algorithm to use for the deterministic encryption.
      DETERMINISTIC_ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_512-Deterministic'

      # The algorithm to use for the non-deterministic encryption.
      RANDOM_ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_512-Random'

      # The mapping of Mongoid field types to BSON type identifiers.
      TYPE_MAPPINGS = {
        Hash => 'object',
        Integer => 'int',
        BSON::Int32 => 'int',
        BSON::Int64 => 'long',
        BSON::ObjectId => 'objectId',
        Time => 'date',
        Date => 'date',
        DateTime => 'date',
        Float => 'double',
        String => 'string',
        BSON::Binary => 'binData',
        Array => 'array',
        Mongoid::Boolean => 'bool',
        BigDecimal => 'decimal',
        Range => 'object',
        Regexp => 'regex',
        Set => 'array',
        Mongoid::StringifiedSymbol => 'string',
        ActiveSupport::TimeWithZone => 'date'
      }.freeze

      # Generate the encryptMetadata object for the provided model.
      #
      # @param [ Mongoid::Document ] model The model to generate the metadata for.
      #
      # @return [ Hash ] The encryptMetadata object.
      def metadata_for(model)
        metadata = {}.tap do |metadata|
          if (key_id = key_id_for(model.encrypt_metadata[:key_id], model.encrypt_metadata[:key_name_field]))
            metadata['keyId'] = key_id
          end
          if model.encrypt_metadata.key?(:deterministic)
            metadata['algorithm'] = if model.encrypt_metadata[:deterministic]
                                      DETERMINISTIC_ALGORITHM
                                    else
                                      RANDOM_ALGORITHM
                                    end
          end
        end
        if metadata.empty?
          {}
        else
          {
            'bsonType' => 'object',
            'encryptMetadata' => metadata
          }
        end
      end

      # Generate encryption properties for the provided model.
      #
      # This method generates the properties for the fields and relations that
      # are marked as encrypted.
      #
      # @param [ Mongoid::Document ] model The model to generate the properties for.
      # @param [ Array<Mongoid::Document> ] path The models the walk is already
      #   inside of, outermost first.
      #
      # @return [ Hash ] The encryption properties.
      def properties_for(model, path)
        result = properties_for_fields(model).merge(properties_for_relations(model, path))
        if result.empty?
          {}
        else
          { 'properties' => result }
        end
      end

      # Generate encryption properties for the fields of the provided model.
      #
      # @param [ Mongoid::Document ] model The model to generate the properties for.
      #
      # @return [ Hash ] The encryption properties.
      def properties_for_fields(model)
        model.fields.each_with_object({}) do |(name, field), props|
          next unless field.is_a?(Mongoid::Fields::Encrypted)

          props[name] = {
            'encrypt' => {
              'bsonType' => bson_type_for(field)
            }
          }
          if (algorithm = algorithm_for(field))
            props[name]['encrypt']['algorithm'] = algorithm
          end
          if (key_id = key_id_for(field.key_id, field.key_name_field))
            props[name]['encrypt']['keyId'] = key_id
          end
        end
      end

      # Generate encryption properties for the relations of the provided model.
      #
      # This method generates the properties for the embedded relations that
      # are configured to be encrypted.
      #
      # @param [ Mongoid::Document ] model The model to generate the properties for.
      # @param [ Array<Mongoid::Document> ] path The models the walk is already
      #   inside of, outermost first.
      #
      # @return [ Hash ] The encryption properties.
      def properties_for_relations(model, path)
        model.relations.each_with_object({}) do |(name, relation), props|
          # relation_class constantizes, and a polymorphic embedded_in has no
          # class to resolve, so the relation type has to be checked first.
          next unless relation.is_a?(Association::Embedded::EmbedsOne)

          klass = relation.try_relation_class
          # An association target does not have to be a Mongoid document, and
          # the class it names does not have to exist.
          next unless klass.respond_to?(:requires_encryption_schema?)
          # Stop at a model the walk is already inside of, or a self-embedding
          # model never terminates. The path covers the current branch only:
          # a model embedded by two parents, or twice by one parent, has to be
          # emitted at every place it appears.
          next if path.include?(klass)
          next unless klass.requires_encryption_schema?

          metadata_for(klass).merge(
            properties_for(klass, path + [ klass ])
          ).tap do |properties|
            props[name] = { 'bsonType' => 'object' }.merge(properties) unless properties.empty?
          end
        end
      end

      # Get the BSON type identifier for the provided field according to the
      # https://www.mongodb.com/docs/manual/reference/bson-types/#std-label-bson-types
      #
      # @param [ Mongoid::Field ] field The field to get the BSON type identifier for.
      #
      # @return [ String ] The BSON type identifier.
      def bson_type_for(field)
        TYPE_MAPPINGS[field.type]
      end

      # Get the encryption algorithm to use for the provided field.
      #
      # @param [ Mongoid::Field ] field The field to get the algorithm for.
      #
      # @return [ String ] The algorithm.
      def algorithm_for(field)
        case field.deterministic?
        when true
          DETERMINISTIC_ALGORITHM
        when false
          RANDOM_ALGORITHM
        else
          nil
        end
      end

      # Get the keyId encryption schema field for the base64 encrypted
      # key id.
      #
      # @param [ String | nil ] key_id_base64 The base64 encoded key id.
      # @param [ String | nil ] key_name_field The name of the key name field.
      #
      # @return [ Array<BSON::Binary> | String | nil ] The keyId encryption schema field,
      #   JSON pointer to the field that contains keyAltName,
      #   or nil if both key_id_base64 and key_name_field are nil.
      def key_id_for(key_id_base64, key_name_field)
        return nil if key_id_base64.nil? && key_name_field.nil?
        if !key_id_base64.nil? && !key_name_field.nil?
          raise ArgumentError, 'Specifying both key_id and key_name_field is not allowed'
        end

        if key_id_base64.nil?
          "/#{key_name_field}"
        else
          [ BSON::Binary.new(Base64.decode64(key_id_base64), :uuid) ]
        end
      end
    end
  end
end
