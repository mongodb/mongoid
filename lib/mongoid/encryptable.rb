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
      # The answer is memoized, since this runs on the persistence path.
      # Declaring encryption on a model after it has already been persisted is
      # not supported.
      #
      # @return [ true | false ] Whether the model needs an encryption schema.
      #
      # @api private
      def requires_encryption_schema?
        return @requires_encryption_schema if defined?(@requires_encryption_schema)

        @requires_encryption_schema = encrypted? || embeds_encrypted?([ self ])
      end

      # Whether any model reachable through this model's embeds_one relations
      # declares encryption.
      #
      # embeds_many is not considered: libmongocrypt cannot express per-field
      # encryption under array items, so those fields are never mapped.
      #
      # @param [ Array<Class> ] path The models the walk is already inside of.
      #   A model embedding itself terminates here.
      #
      # @return [ true | false ] Whether an embedded model is encrypted.
      #
      # @api private
      def embeds_encrypted?(path)
        relations.each_value.any? do |relation|
          next false unless relation.is_a?(Association::Embedded::EmbedsOne)

          klass = relation.try_relation_class
          # An association target does not have to be a Mongoid document, and
          # the class it names does not have to exist.
          next false unless klass.respond_to?(:encrypted?)
          next false if path.include?(klass)

          klass.encrypted? || klass.embeds_encrypted?(path + [ klass ])
        end
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
