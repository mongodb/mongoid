# encoding: utf-8
module Origin

  # The options is a hash representation of options passed to MongoDB queries,
  # such as skip, limit, and sorting criteria.
  class Options < Smash

    # Convenience method for getting the field options.
    #
    # @example Get the fields options.
    #   options.fields
    #
    # @return [ Hash ] The fields options.
    #
    # @since 1.0.0
    def fields
      self[:fields]
    end

    # Convenience method for getting the limit option.
    #
    # @example Get the limit option.
    #   options.limit
    #
    # @return [ Integer ] The limit option.
    #
    # @since 1.0.0
    def limit
      self[:limit]
    end

    # Convenience method for getting the skip option.
    #
    # @example Get the skip option.
    #   options.skip
    #
    # @return [ Integer ] The skip option.
    #
    # @since 1.0.0
    def skip
      self[:skip]
    end

    # Convenience method for getting the sort options.
    #
    # @example Get the sort options.
    #   options.sort
    #
    # @return [ Hash ] The sort options.
    #
    # @since 1.0.0
    def sort
      self[:sort]
    end

    # Store the value in the options for the provided key. The options will
    # handle all necessary serialization and localization in this step.
    #
    # @example Store a value in the options.
    #   options.store(:key, "testing")
    #
    # @param [ String, Symbol ] key The name of the attribute.
    # @param [ Object ] value The value to add.
    #
    # @return [ Object ] The stored object.
    #
    # @since 1.0.0
    def store(key, value)
      super(key, evolve(value))
    end
    alias :[]= :store

    # Convert the options to aggregation pipeline friendly options.
    #
    # @example Convert the options to a pipeline.
    #   options.to_pipeline
    #
    # @return [ Array<Hash> ] The options in pipeline form.
    #
    # @since 2.0.0
    def to_pipeline
      pipeline = []
      pipeline.push({ "$skip" => skip }) if skip
      pipeline.push({ "$limit" => limit }) if limit
      pipeline.push({ "$sort" => sort }) if sort
      pipeline
    end

    private

    # Evolve a single key selection with various types of values.
    #
    # @api private
    #
    # @example Evolve a simple selection.
    #   options.evolve(field, 5)
    #
    # @param [ Object ] value The value to serialize.
    #
    # @return [ Object ] The serialized object.
    #
    # @since 1.0.0
    def evolve(value)
      case value
      when Hash
        evolve_hash(value)
      else
        value
      end
    end

    # Evolve a single key selection with hash values.
    #
    # @api private
    #
    # @example Evolve a simple selection.
    #   options.evolve(field, { "$gt" => 5 })
    #
    # @param [ Hash ] value The hash to serialize.
    #
    # @return [ Object ] The serialized hash.
    #
    # @since 1.0.0
    def evolve_hash(value)
      value.inject({}) do |hash, (field, _value)|
        name, serializer = storage_pair(field)
        hash[normalized_key(name, serializer)] = _value
        hash
      end
    end
  end
end
