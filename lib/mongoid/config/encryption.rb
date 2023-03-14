# frozen_string_literal: true

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
      # @param [ Array<Mongoid::Document> ] models The models to generate the schema map for.
      #   Defaults to all models in the application.
      # @return [ Hash ] The encryption schema map.
      def encryption_schema_map(models = ::Mongoid.models)
        models.each_with_object({}) do |model, map|
          next if model.embedded?

          key = "#{model.persistence_context.database_name}.#{model.persistence_context.collection_name}"
          props = metadata_for(model).merge(properties_for(model))
          map[key] = props unless props.empty?
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
      # @return [ Hash ] The encryptMetadata object.
      def metadata_for(model)
        metadata = {}.tap do |metadata|
          if (key_id = key_id_for(model.encrypt_metadata[:key_id]))
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
      # @return [ Hash ] The encryption properties.
      def properties_for(model)
        result = properties_for_fields(model).merge(properties_for_relations(model))
        if result.empty?
          {}
        else
          { 'properties' => result }
        end
      end

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
          if (key_id = key_id_for(field.key_id))
            props[name]['encrypt']['keyId'] = key_id
          end
        end
      end

      def properties_for_relations(model)
        model.relations.each_with_object({}) do |(name, relation), props|
          next unless relation.is_a?(Association::Embedded::EmbedsMany) ||
                      relation.is_a?(Association::Embedded::EmbedsOne)

          metadata_for(
            relation.relation_class
          ).merge(
            properties_for(relation.relation_class)
          ).tap do |properties|
            props[name] = { 'bsonType' => 'object' }.merge(properties) unless properties.empty?
          end
        end
      end

      def bson_type_for(field)
        TYPE_MAPPINGS[field.type]
      end

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

      def key_id_for(key_id_base64)
        return nil unless key_id_base64

        [ BSON::Binary.new(Base64.decode64(key_id_base64), :uuid) ]
      end
    end
  end
end
