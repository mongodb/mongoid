# frozen_string_literal: true

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
        superficial_match?(key: other.key)
      end

      # Performs a superficial comparison with the given criteria, checking
      # only the key and (optionally) the name. Options are not compared.
      #
      # Note that the ordering of the fields in the key is significant. Two
      # keys with different orderings will not match, here.
      #
      # @param [ Hash ] key the key that defines the index.
      # @param [ String | nil ] name the name given to the index, or nil to
      #    ignore the name.
      #
      # @return [ true | false ] the result of the comparison, true if this
      #   specification matches the criteria, and false otherwise.
      def superficial_match?(key: {}, name: nil)
        (name && name == self.name) ||
          self.fields == key.keys &&
          self.key == key
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
        @key = normalize_key(key)
        @fields = @key.keys
        @options = normalize_options(options.dup)
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

      # Normalize the spec, in case aliased fields are provided.
      #
      # @api private
      #
      # @example Normalize the spec.
      #   specification.normalize_key(name: 1)
      #
      # @param [ Hash ] key The index key(s).
      #
      # @return [ Hash ] The normalized specification.
      def normalize_key(key)
        normalized = {}
        key.each_pair do |name, direction|
          normalized[klass.database_field_name(name).to_sym] = direction
        end
        normalized
      end

      # Normalize the index options, if any are provided.
      #
      # @api private
      #
      # @example Normalize the index options.
      #   specification.normalize_options(unique: true)
      #
      # @param [ Hash ] opts The index options.
      #
      # @return [ Hash ] The normalized options.
      def normalize_options(opts)
        options = {}
        opts.each_pair do |option, value|
          options[MAPPINGS[option] || option] = value
        end
        options
      end
    end
  end
end
