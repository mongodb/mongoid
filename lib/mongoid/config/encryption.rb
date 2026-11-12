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
      # @param [ String ] default_database The default database name.
      # @param [ Array<Mongoid::Document> ] models The models to generate the schema map for.
      #   Defaults to all models in the application.
      #
      # @return [ Hash ] The encryption schema map.
      def encryption_schema_map(default_database, models = ::Mongoid.models)
        # Subclasses share their parent's collection but are not registered in
        # Mongoid.models, so they have to be added to the walk explicitly.
        classes = models.flat_map { |model| [ model ] + model.descendants }.uniq

        classes.each_with_object({}) do |model, map|
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
          props = metadata_for(model).merge(properties_for(model, [ model ], key))
          next if props.empty?

          # The root of a collection schema describes the document, so it is
          # always an object. Saying so matters when a nested schema carries
          # encryptMetadata: mongocryptd rejects the schema otherwise.
          entry = { 'bsonType' => 'object' }.merge(props)
          map[key] = map.key?(key) ? merge_schema_entries(map[key], entry, key) : entry
        end
      end

      # Collect the paths of the fields encrypted by the schema generated for
      # a single model.
      #
      # @param [ Mongoid::Document ] model The model.
      #
      # @return [ Array<Array<String>> ] The property paths, outermost first.
      #
      # @api private
      def encrypted_paths_for(model)
        return model.instance_variable_get(:@encrypted_paths_for) if
          model.instance_variable_defined?(:@encrypted_paths_for)

        properties = properties_for(model, [ model ])['properties'] || {}
        model.instance_variable_set(:@encrypted_paths_for, collect_encrypted_paths(properties, []))
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
      # @param [ String | nil ] namespace The namespace the schema is built
      #   for, used for error reporting.
      #
      # @return [ Hash ] The encryption properties.
      def properties_for(model, path, namespace = nil)
        result = properties_for_fields(model).merge(properties_for_relations(model, path, namespace))
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
      # @param [ String | nil ] namespace The namespace the schema is built
      #   for, used for error reporting.
      #
      # @return [ Hash ] The encryption properties.
      def properties_for_relations(model, path, namespace = nil)
        model.relations.each_with_object({}) do |(name, relation), props|
          # relation_class constantizes, and a polymorphic embedded_in has no
          # class to resolve, so the relation type has to be checked first.
          next unless relation.is_a?(Association::Embedded::EmbedsOne)

          klass = relation.try_relation_class
          # An association target does not have to be a Mongoid document, and
          # the class it names does not have to exist.
          next unless klass.respond_to?(:requires_encryption_schema?)

          # Any subclass of the declared class can be assigned to the
          # association, so its encrypted fields have to be mapped here too.
          properties = ([ klass ] + klass.descendants).uniq.inject({}) do |merged, candidate|
            # Stop at a model the walk is already inside of, or a self-embedding
            # model never terminates. The path covers the current branch only:
            # a model embedded by two parents, or twice by one parent, has to be
            # emitted at every place it appears.
            next merged if path.include?(candidate)
            next merged unless candidate.respond_to?(:requires_encryption_schema?)
            next merged unless candidate.requires_encryption_schema?

            merge_schema_entries(
              merged,
              metadata_for(candidate).merge(
                properties_for(candidate, path + [ candidate ], namespace)
              ),
              namespace
            )
          end
          props[name] = { 'bsonType' => 'object' }.merge(properties) unless properties.empty?
        end
      end

      # Walk the schema properties and collect the path of every encrypted
      # leaf.
      #
      # @param [ Hash ] properties The properties to walk.
      # @param [ Array<String> ] path The properties the walk is already
      #   inside of.
      #
      # @return [ Array<Array<String>> ] The property paths.
      def collect_encrypted_paths(properties, path)
        properties.each_with_object([]) do |(name, schema), paths|
          if schema.key?('encrypt')
            paths << (path + [ name ])
          elsif schema['properties']
            paths.concat(collect_encrypted_paths(schema['properties'], path + [ name ]))
          end
        end
      end

      # Merge two schema objects covering the same model or namespace.
      #
      # Every model writing to one namespace contributes an entry to the
      # schema map. Those entries have to agree on everything they have in
      # common, or the schema would silently encrypt a field differently for
      # one model than for another.
      #
      # @param [ Hash ] left The first schema.
      # @param [ Hash ] right The second schema.
      # @param [ String | nil ] namespace The namespace the schema belongs to.
      #
      # @return [ Hash ] The merged schema.
      def merge_schema_entries(left, right, namespace = nil)
        left.merge(right) do |key, left_value, right_value|
          case key
          when 'bsonType'
            left_value
          when 'encryptMetadata'
            merge_encrypt_metadata(left_value, right_value, namespace)
          when 'properties'
            merge_properties(left_value, right_value, namespace)
          else
            raise_invalid_encryption_schema(namespace, key)
          end
        end
      end

      # Merge two encryptMetadata objects.
      #
      # @param [ Hash ] left The first encryptMetadata object.
      # @param [ Hash ] right The second encryptMetadata object.
      # @param [ String | nil ] namespace The namespace the schema belongs to.
      #
      # @return [ Hash ] The merged encryptMetadata object.
      def merge_encrypt_metadata(left, right, namespace)
        left.merge(right) do |key, left_value, right_value|
          unless left_value == right_value
            raise_invalid_encryption_schema(namespace, "encryptMetadata.#{key}")
          end

          left_value
        end
      end

      # Merge two properties objects.
      #
      # @param [ Hash ] left The first properties object.
      # @param [ Hash ] right The second properties object.
      # @param [ String | nil ] namespace The namespace the schema belongs to.
      #
      # @return [ Hash ] The merged properties object.
      def merge_properties(left, right, namespace)
        left.merge(right) do |name, left_value, right_value|
          if left_value.key?('encrypt') && right_value.key?('encrypt')
            unless left_value['encrypt'] == right_value['encrypt']
              raise_invalid_encryption_schema(namespace, "properties.#{name}")
            end

            left_value
          elsif left_value.key?('encrypt') || right_value.key?('encrypt')
            raise_invalid_encryption_schema(namespace, "properties.#{name}")
          else
            merge_schema_entries(left_value, right_value, namespace)
          end
        end
      end

      # Raise an error for a schema conflicting with another one.
      #
      # @param [ String | nil ] namespace The namespace the schema belongs to.
      # @param [ String ] path The conflicting path in the schema.
      #
      # @raise [ Errors::InvalidEncryptionSchema ] Always raised.
      def raise_invalid_encryption_schema(namespace, path)
        raise Errors::InvalidEncryptionSchema.new(namespace, path)
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
