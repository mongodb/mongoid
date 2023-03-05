# frozen_string_literal: true

module Mongoid
  class Criteria
    module Queryable

      # Key objects represent specifications for building query expressions
      # utilizing MongoDB selectors.
      #
      # Simple key-value conditions are translated directly into expression
      # hashes by Mongoid without utilizing Key objects. For example, the
      # following condition:
      #
      #   Foo.where(price: 1)
      #
      # ... is translated to the following simple expression:
      #
      #   {price: 1}
      #
      # More complex conditions would start involving Key objects. For example:
      #
      #   Foo.where(:price.gt => 1)
      #
      # ... causes a Key instance to be created as follows:
      #
      #   Key.new(:price, :__override__, '$gt')
      #
      # This Key instance utilizes +operator+ but not +expanded+ nor +block+.
      # The corresponding MongoDB query expression is:
      #
      #    {price: {'$gt' => 1}}
      #
      # A yet more more complex example is the following condition:
      #
      #   Foo.geo_spatial(:boundary.intersects_point => [1, 10])
      #
      # Processing this condition will cause a Key instance to be created as
      # follows:
      #
      #   Key.new(:location, :__override__, '$geoIntersects', '$geometry') do |value|
      #     { "type" => POINT, "coordinates" => value }
      #   end
      #
      # ... eventually producing the following MongoDB query expression:
      #
      # {
      #   boundary: {
      #     '$geoIntersects' => {
      #       '$geometry' => {
      #         type: "Point" ,
      #         coordinates: [ 1, 10 ]
      #       }
      #     }
      #   }
      # }
      #
      # Key instances can be thought of as procs that map a value to the
      # MongoDB query expression required to obtain the key's condition,
      # given the value.
      class Key

        # @return [ String | Symbol ] The name of the field.
        attr_reader :name

        # @return [ String ] The MongoDB query operator.
        attr_reader :operator

        # @return [ String ] The MongoDB expanded query operator.
        attr_reader :expanded

        # @return [ Symbol ] The name of the merge strategy.
        attr_reader :strategy

        # @return [ Proc ] The optional block to transform values.
        attr_reader :block

        # Does the key equal another object?
        #
        # @example Is the key equal to another?
        #   key == other
        #   key.eql? other
        #
        # @param [ Object ] other The object to compare to.
        #
        # @return [ true | false ] If the objects are equal.
        def ==(other)
          return false unless other.is_a?(Key)
          name == other.name && operator == other.operator && expanded == other.expanded
        end
        alias :eql? :==

        # Calculate the hash code for a key.
        #
        # @return [ Integer ] The hash code for the key.
        def hash
          [name, operator, expanded].hash
        end

        # Instantiate the new key.
        #
        # @example Instantiate a key.
        #   Key.new("age", :__override__, "$gt")
        #
        # @example Instantiate a key for sorting.
        #   Key.new(:field, :__override__, 1)
        #
        # @param [ String | Symbol ] name The field name.
        # @param [ Symbol ] strategy The name of the merge strategy.
        # @param [ String | Integer ] operator The MongoDB operator,
        #   or sort direction (1 or -1).
        # @param [ String ] expanded The Mongo expanded operator.
        def initialize(name, strategy, operator, expanded = nil, &block)
          unless operator.is_a?(String) || operator.is_a?(Integer)
            raise ArgumentError, "Operator must be a string or an integer: #{operator.inspect}"
          end

          @name, @strategy, @operator, @expanded, @block =
            name, strategy, operator, expanded, block
        end

        # Gets the raw selector that would be passed to Mongo from this key.
        #
        # @example Specify the raw selector.
        #   key.__expr_part__(50)
        #
        # @param [ Object ] object The value to be included.
        # @param [ true | false ] negating If the selection should be negated.
        #
        # @return [ Hash ] The raw MongoDB selector.
        def __expr_part__(object, negating = false)
          { name.to_s => transform_value(object, negating) }
        end

        def transform_value(value, negating = false)
          if block
            expr = block[value]
          else
            expr = value
          end

          if expanded
            expr = {expanded => expr}
          end

          expr = {operator => expr}

          if negating && operator != '$not'
            expr = {'$not' => expr}
          end

          expr
        end

        # Get the key as raw Mongo sorting options.
        #
        # @example Get the key as a sort.
        #   key.__sort_option__
        #
        # @return [ Hash ] The field/direction pair.
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
        def to_s
          @name.to_s
        end
      end
    end
  end
end
