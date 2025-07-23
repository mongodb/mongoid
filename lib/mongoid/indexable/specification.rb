# frozen_string_literal: true
# rubocop:todo all

module Mongoid
  module Indexable

    # Encapsulates behavior around an index specification.
    class Specification

      # The mappings of nice Ruby-style names to the corresponding driver
      # option name.
      MAPPINGS = {
        expire_after_seconds: :expire_after
      }

      # @!attribute klass
      #   @return [ Class ] The class the index is defined on.
      # @!attribute key
      #   @return [ Hash ] The index key.
      # @!attribute options
      #   @return [ Hash ] The index options.
      attr_reader :klass, :key, :fields, :options

      # Is this index specification equal to another?
      #
      # @example Check equality of the specifications.
      #   specification == other
      #
      # @param [ Specification ] other The spec to compare against.
      #
      # @return [ true | false ] If the specs are equal.
      def ==(other)
        fields == other.fields && key == other.key
      end

      # Instantiate a new index specification.
      #
      # @example Create the new specification.
      #   Specification.new(Band, { name: 1 }, background: true)
      #
      # @param [ Class ] klass The class the index is defined on.
      # @param [ Hash ] key The hash of name/direction pairs.
      # @param [ Hash ] opts the index options.
      def initialize(klass, key, opts = nil)
        options = opts || {}
        Validators::Options.validate(klass, key, options)
        @klass = klass
        @key = normalize_aliases!(key.dup)
        @fields = @key.keys
        @options = normalize_options!(options.deep_dup)
      end

      # Get the index name, generated using the index key.
      #
      # @example Get the index name.
      #   specification.name
      #
      # @return [ String ] name The index name.
      def name
        @name ||= key.reduce([]) do |n, (k,v)|
          n << "#{k}_#{v}"
        end.join('_')
      end

      private

      # Normalize the spec in-place, in case aliased fields are provided.
      #
      # @api private
      #
      # @example Normalize the spec in-place.
      #   specification.normalize_aliases!(name: 1)
      #
      # @param [ Hash ] spec The index specification.
      #
      # @return [ Hash ] The normalized specification.
      def normalize_aliases!(spec)
        return unless spec.is_a?(Hash)

        spec.transform_keys! do |name|
          klass.database_field_name(name).to_sym
        end
      end

      # Normalize the index options in-place. Performs deep normalization
      # on options which have a fields hash value.
      #
      # @api private
      #
      # @example Normalize the index options in-place.
      #   specification.normalize_options!(unique: true)
      #
      # @param [ Hash ] options The index options.
      #
      # @return [ Hash ] The normalized options.
      def normalize_options!(options)

        options.transform_keys! do |option|
          option = option.to_sym
          MAPPINGS[option] || option
        end

        %i[partial_filter_expression weights wildcard_projection].each do |key|
          recursive_normalize_conditionals!(options[key])
        end

        options
      end

      # Recursively normalizes the nested elements of an options hash in-place,
      # to account for $and operator (and other potential $-prefixed operators
      # which may be supported by MongoDB in the future.)
      #
      # @api private
      #
      # @example Recursively normalize the index options in-place.
      #   opts = { '$and' => [{ name: { '$eq' => 'Bob' } },
      #                       { age: { '$gte' => 20 } }] }
      #   specification.recursive_normalize_conditionals!(opts)
      #
      # @param [ Hash | Array | Object ] options The index options.
      #
      # @return [ Hash | Array | Object ] The normalized options.
      def recursive_normalize_conditionals!(options)
        case options
        when Hash
          normalize_aliases!(options)
          options.keys.select { |key| key.to_s.start_with?('$') }.each do |key|
            recursive_normalize_conditionals!(options[key])
          end
        when Array
          options.each { |opt| recursive_normalize_conditionals!(opt) }
        end

        options
      end
    end
  end
end
