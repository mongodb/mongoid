# encoding: utf-8
module Origin

  # Represents an aggregation pipeline.
  #
  # @since 2.0.0
  class Pipeline < Array

    # @attribute [r] aliases The field aliases.
    attr_reader :aliases

    # Deep copy the aggregation pipeline. Will clone all the values in the
    # pipeline as well as the pipeline itself.
    #
    # @example Deep copy the pipeline.
    #   pipeline.__deep_copy__
    #
    # @return [ Pipeline ] The cloned pipeline.
    #
    # @since 2.0.0
    def __deep_copy__
      self.class.new(aliases) do |copy|
        each do |entry|
          copy.push(entry.__deep_copy__)
        end
      end
    end

    # Add a group operation to the aggregation pipeline.
    #
    # @example Add a group operation.
    #   pipeline.group(:count.sum => 1, :max.max => "likes")
    #
    # @param [ Hash ] entry The group entry.
    #
    # @return [ Pipeline ] The pipeline.
    #
    # @since 2.0.0
    def group(entry)
      push("$group" => evolve(entry.__expand_complex__))
    end

    # Initialize the new pipeline.
    #
    # @example Initialize the new pipeline.
    #   Origin::Pipeline.new(aliases)
    #
    # @param [ Hash ] aliases A hash of mappings from aliases to the actual
    #   field names in the database.
    #
    # @since 2.0.0
    def initialize(aliases = {})
      @aliases = aliases
      yield(self) if block_given?
    end

    # Adds a $project entry to the aggregation pipeline.
    #
    # @example Add the projection.
    #   pipeline.project(name: 1)
    #
    # @param [ Hash ] entry The projection.
    #
    # @return [ Pipeline ] The pipeline.
    def project(entry)
      push("$project" => evolve(entry))
    end

    # Add the $unwind entry to the pipeline.
    #
    # @example Add the unwind.
    #   pipeline.unwind(:field)
    #
    # @param [ String, Symbol ] field The name of the field.
    #
    # @return [ Pipeline ] The pipeline.
    #
    # @since 2.0.0
    def unwind(field)
      normalized = field.to_s
      name = aliases[normalized] || normalized
      push("$unwind" => name.__mongo_expression__)
    end

    private

    # Evolve the entry using the aliases.
    #
    # @api private
    #
    # @example Evolve the entry.
    #   pipeline.evolve(name: 1)
    #
    # @param [ Hash ] entry The entry to evolve.
    #
    # @return [ Hash ] The evolved entry.
    #
    # @since 2.0.0
    def evolve(entry)
      aggregate = Selector.new(aliases)
      entry.each_pair do |field, value|
        aggregate.merge!(field.to_s => value)
      end
      aggregate
    end
  end
end
