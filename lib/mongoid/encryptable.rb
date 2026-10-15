module Mongoid
  # This module is used to extend Mongoid::Document
  # to add encryption functionality.
  module Encryptable
    extend ActiveSupport::Concern

    included do
      # @return [Hash] The encryption metadata for the model.
      class_attribute :encrypt_metadata
      self.encrypt_metadata = {}
    end

    module ClassMethods
      # Set the encryption metadata for the model. Parameters set here will be
      # used to encrypt the fields of the model, unless overridden on the
      # field itself.
      #
      # @param [ Hash ] options The encryption metadata.
      # @option options [ String ] :key_id The base64-encoded UUID of the key
      #   used to encrypt fields. Mutually exclusive with :key_name_field option.
      # @option options [ String ] :key_name_field The name of the field that
      #   contains the key alt name to use for encryption. Mutually exclusive
      #   with :key_id option.
      # @option options [ true | false ] :deterministic Whether the encryption
      # is deterministic or not.
      def encrypt_with(options = {})
        self.encrypt_metadata = options
      end

      # Whether the model is encrypted. It means that either the encrypt_with
      # method was called on the model, or at least one of the fields
      # is encrypted.
      #
      # @return [ true | false ] Whether the model is encrypted.
      def encrypted?
        !encrypt_metadata.empty? || fields.any? { |_, field| field.is_a?(Mongoid::Fields::Encrypted) }
      end

      # Whether an encryption schema has to be generated for this model.
      #
      # True when the model declares encryption itself, and also when any model
      # reachable through its embeds_one relations does. A model in the second
      # group has no encrypted field of its own, but its collection still needs
      # a schema, otherwise the embedded fields are written in plaintext.
      #
      # This runs on the persistence path, so the answer is memoized. A true
      # answer is always memoized. A false answer is memoized only when every
      # embeds_one target in the walk resolved to a class; if one could not be
      # resolved yet, the answer is recomputed next time, so a class loaded
      # later is still detected. Declaring encryption on a model after it has
      # already been persisted is not supported.
      #
      # @return [ true | false ] Whether the model needs an encryption schema.
      #
      # @api private
      def requires_encryption_schema?
        return @requires_encryption_schema if defined?(@requires_encryption_schema)
        return @requires_encryption_schema = true if encrypted?

        found, complete = embedded_encryption_scan([ self ])
        @requires_encryption_schema = found if found || complete
        found
      end

      # Walks the models reachable through this model's embeds_one relations,
      # looking for one that declares encryption.
      #
      # embeds_many is not considered: libmongocrypt cannot express per-field
      # encryption under array items, so those fields are never mapped.
      #
      # @param [ Array<Class> ] path The models the walk is already inside of.
      #   A model embedding itself terminates here.
      #
      # @return [ Array<true | false> ] A pair: whether an embedded model is
      #   encrypted, and whether every embeds_one target the walk needed
      #   resolved to a class. The second value is only meaningful when the
      #   first is false.
      #
      # @api private
      def embedded_encryption_scan(path)
        complete = true

        relations.each_value do |relation|
          next unless relation.is_a?(Association::Embedded::EmbedsOne)

          klass = relation.try_relation_class
          # The class an association names does not have to exist yet.
          if klass.nil?
            complete = false
            next
          end

          # An association target does not have to be a Mongoid document.
          next unless klass.respond_to?(:encrypted?)
          next if path.include?(klass)
          return [ true, true ] if klass.encrypted?

          found, nested_complete = klass.embedded_encryption_scan(path + [ klass ])
          return [ true, true ] if found

          complete &&= nested_complete
        end

        [ false, complete ]
      end

      # Override the key_id for the model.
      #
      # This method is solely for testing purposes and should not be used in
      # the application code. The schema_map is generated very early in the
      # application lifecycle, and overriding the key_id after that will not
      # have any effect.
      #
      # @api private
      def set_key_id(key_id)
        encrypt_metadata[:key_id] = key_id
      end
    end
  end
end
