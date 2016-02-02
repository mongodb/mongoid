# encoding: utf-8
module Origin

  # This is a smart hash for use with options and selectors.
  class Smash < Hash

    # @attribute [r] aliases The aliases.
    # @attribute [r] serializers The serializers.
    attr_reader :aliases, :serializers

    # Perform a deep copy of the smash.
    #
    # @example Perform a deep copy.
    #   smash.__deep_copy__
    #
    # @return [ Smash ] The copied hash.
    #
    # @since 1.0.0
    def __deep_copy__
      self.class.new(aliases, serializers) do |copy|
        each_pair do |key, value|
          copy.store(key, value.__deep_copy__)
        end
      end
    end

    # Initialize the new selector.
    #
    # @example Initialize the new selector.
    #   Origin::Smash.new(aliases, serializers)
    #
    # @param [ Hash ] aliases A hash of mappings from aliases to the actual
    #   field names in the database.
    # @param [ Hash ] serializers An optional hash of objects that are
    #   responsible for serializing values. The keys of the hash must be
    #   strings that match the field name, and the values must respond to
    #   #localized? and #evolve(object).
    #
    # @since 1.0.0
    def initialize(aliases = {}, serializers = {})
      @aliases, @serializers = aliases, serializers
      yield(self) if block_given?
    end

    # Get an item from the smart hash by the provided key.
    #
    # @example Get an item by the key.
    #   smash["test"]
    #
    # @param [ String ] key The key.
    #
    # @return [ Object ] The found object.
    #
    # @since 2.0.0
    def [](key)
      fetch(aliases[key]) { super }
    end

    private

    # Get the normalized value for the key. If localization is in play the
    # current locale will be appended to the key in MongoDB dot notation.
    #
    # @api private
    #
    # @example Get the normalized key name.
    #   smash.normalized_key("field", serializer)
    #
    # @param [ String ] name The name of the field.
    # @param [ Object ] serializer The optional field serializer.
    #
    # @return [ String ] The normalized key.
    #
    # @since 1.0.0
    def normalized_key(name, serializer)
      serializer && serializer.localized? ? "#{name}.#{::I18n.locale}" : name
    end

    # Get the pair of objects needed to store the value in a hash by the
    # provided key. This is the database field name and the serializer.
    #
    # @api private
    #
    # @example Get the name and serializer.
    #   smash.storage_pair("id")
    #
    # @param [ Symbol, String ] key The key provided to the selection.
    #
    # @return [ Array<String, Object> ] The name of the db field and
    #   serializer.
    #
    # @since 1.0.0
    def storage_pair(key)
      field = key.to_s
      name = aliases[field] || field
      [ name, serializers[name] ]
    end
  end
end
