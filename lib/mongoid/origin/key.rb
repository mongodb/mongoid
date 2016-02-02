# encoding: utf-8
module Origin

  # The key is a representation of a field in a queryable, that can be
  # expanded to special MongoDB selectors.
  class Key

    # @attribute [r] name The name of the field.
    # @attribute [r] block The optional block to transform values.
    # @attribute [r] operator The MongoDB query operator.
    # @attribute [r] expanded The MongoDB expanded query operator.
    # @attribute [r] strategy The name of the merge strategy.
    attr_reader :block, :name, :operator, :expanded, :strategy

    # Does the key equal another object?
    #
    # @example Is the key equal to another?
    #   key == other
    #   key.eql? other
    #
    # @param [ Object ] other The object to compare to.
    #
    # @return [ true, false ] If the objects are equal.
    #
    # @since 1.0.0
    def ==(other)
      return false unless other.is_a?(Key)
      name == other.name && operator == other.operator && expanded == other.expanded
    end
    alias :eql? :==

    # Calculate the hash code for a key.
    #
    # @return [ Fixnum ] The hash code for the key.
    #
    # @since 1.1.0
    def hash
      [name, operator, expanded].hash
    end

    # Instantiate the new key.
    #
    # @example Instantiate the key.
    #   Key.new("age", "$gt")
    #
    # @param [ String, Symbol ] name The field name.
    # @param [ Symbol ] strategy The name of the merge strategy.
    # @param [ String ] operator The Mongo operator.
    # @param [ String ] expanded The Mongo expanded operator.
    #
    # @since 1.0.0
    def initialize(name, strategy, operator, expanded = nil, &block)
      @name, @strategy, @operator, @expanded, @block =
        name, strategy, operator, expanded, block
    end

    # Gets the raw selector that would be passed to Mongo from this key.
    #
    # @example Specify the raw selector.
    #   key.__expr_part__(50)
    #
    # @param [ Object ] object The value to be included.
    # @param [ true, false ] negating If the selection should be negated.
    #
    # @return [ Hash ] The raw MongoDB selector.
    #
    # @since 1.0.0
    def __expr_part__(object, negating = false)
      value = block ? block[object] : object
      expression = { operator => expanded ? { expanded => value } : value }
      { name.to_s => (negating && operator != "$not") ? { "$not" => expression } : expression }
    end

    # Get the key as raw Mongo sorting options.
    #
    # @example Get the key as a sort.
    #   key.__sort_option__
    #
    # @return [ Hash ] The field/direction pair.
    #
    # @since 1.0.0
    def __sort_option__
      { name => operator }
    end
    alias :__sort_pair__ :__sort_option__

    # Convert the key to a string.
    #
    # @example Convert the key to a string.
    #   key.to_s
    #
    # @return [ String ] The key as a string.
    #
    # @since 1.1.0
    def to_s
      @name.to_s
    end
  end
end
