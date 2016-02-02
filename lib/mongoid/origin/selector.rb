# encoding: utf-8
module Origin

  # The selector is a special kind of hash that knows how to serialize values
  # coming into it as well as being alias and locale aware for key names.
  class Selector < Smash

    # Merges another selector into this one.
    #
    # @example Merge in another selector.
    #   selector.merge!(name: "test")
    #
    # @param [ Hash, Selector ] other The object to merge in.
    #
    # @return [ Selector ] The selector.
    #
    # @since 1.0.0
    def merge!(other)
      other.each_pair do |key, value|
        if value.is_a?(Hash) && self[key.to_s].is_a?(Hash)
          value = self[key.to_s].merge(value) do |_key, old_val, new_val|
            multi_value?(_key) ? (old_val + new_val).uniq : new_val
          end
        end
        if multi_selection?(key)
          value = (self[key.to_s] || []).concat(value)
        end
        store(key, value)
      end
    end

    # Store the value in the selector for the provided key. The selector will
    # handle all necessary serialization and localization in this step.
    #
    # @example Store a value in the selector.
    #   selector.store(:key, "testing")
    #
    # @param [ String, Symbol ] key The name of the attribute.
    # @param [ Object ] value The value to add.
    #
    # @return [ Object ] The stored object.
    #
    # @since 1.0.0
    def store(key, value)
      name, serializer = storage_pair(key)
      if multi_selection?(name)
        super(name, evolve_multi(value))
      else
        super(normalized_key(name, serializer), evolve(serializer, value))
      end
    end
    alias :[]= :store

    # Convert the selector to an aggregation pipeline entry.
    #
    # @example Convert the selector to a pipeline.
    #   selector.to_pipeline
    #
    # @return [ Array<Hash> ] The pipeline entry for the selector.
    #
    # @since 2.0.0
    def to_pipeline
      pipeline = []
      pipeline.push({ "$match" => self }) unless empty?
      pipeline
    end

    private

    # Evolves a multi-list selection, like an $and or $or criterion, and
    # performs the necessary serialization.
    #
    # @api private
    #
    # @example Evolve the multi-selection.
    #   selector.evolve_multi([{ field: "value" }])
    #
    # @param [ Array<Hash> ] The multi-selection.
    #
    # @return [ Array<Hash> ] The serialized values.
    #
    # @since 1.0.0
    def evolve_multi(value)
      value.map do |val|
        Hash[val.map do |key, _value|
          _value = evolve_multi(_value) if multi_selection?(key)
          name, serializer = storage_pair(key)
          [ normalized_key(name, serializer), evolve(serializer, _value) ]
        end]
      end.uniq
    end

    # Evolve a single key selection with various types of values.
    #
    # @api private
    #
    # @example Evolve a simple selection.
    #   selector.evolve(field, 5)
    #
    # @param [ Object ] serializer The optional serializer for the field.
    # @param [ Object ] value The value to serialize.
    #
    # @return [ Object ] The serialized object.
    #
    # @since 1.0.0
    def evolve(serializer, value)
      case value
      when Hash
        evolve_hash(serializer, value)
      when Array
        evolve_array(serializer, value)
      else
        (serializer || value.class).evolve(value)
      end
    end

    # Evolve a single key selection with array values.
    #
    # @api private
    #
    # @example Evolve a simple selection.
    #   selector.evolve(field, [ 1, 2, 3 ])
    #
    # @param [ Object ] serializer The optional serializer for the field.
    # @param [ Array<Object> ] value The array to serialize.
    #
    # @return [ Object ] The serialized array.
    #
    # @since 1.0.0
    def evolve_array(serializer, value)
      value.map do |_value|
        evolve(serializer, _value)
      end
    end

    # Evolve a single key selection with hash values.
    #
    # @api private
    #
    # @example Evolve a simple selection.
    #   selector.evolve(field, { "$gt" => 5 })
    #
    # @param [ Object ] serializer The optional serializer for the field.
    # @param [ Hash ] value The hash to serialize.
    #
    # @return [ Object ] The serialized hash.
    #
    # @since 1.0.0
    def evolve_hash(serializer, value)
      value.each_pair do |operator, _value|
        if operator =~ /exists|type|size/
          value[operator] = _value
        else
          value[operator] = evolve(serializer, _value)
        end
      end
    end

    # Determines if the selection is a multi-select, like an $and or $or or $nor
    # selection.
    #
    # @api private
    #
    # @example Is the selection a multi-select?
    #   selector.multi_selection?("$and")
    #
    # @param [ String ] key The key to check.
    #
    # @return [ true, false ] If the key is for a multi-select.
    #
    # @since 1.0.0
    def multi_selection?(key)
      key =~ /\$and|\$or|\$nor/
    end

    # Determines if the selection operator takes a list. Returns true for $in and $nin.
    #
    # @api private
    #
    # @example Does the selection operator take multiple values?
    #   selector.multi_value?("$nin")
    #
    # @param [ String ] key The key to check.
    #
    # @return [ true, false ] If the key is $in or $nin.
    #
    # @since 2.1.1
    def multi_value?(key)
      key =~ /\$nin|\$in/
    end
  end
end
