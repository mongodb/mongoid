# frozen_string_literal: true

module Mongoid
  class TypedArray < ::Array

    # The enforced class of all of the elements in the array.
    #
    # @return [ Class ] The inner class of the array.
    attr_reader :element_klass

    # Initialize a typed array. Sets the element klass and demongoizes all of the
    # elements in the given array.
    #
    # @param [ Class ] type The inner type of the array.
    # @param [ Array ] array The array.
    def initialize(type, *args, &block)
      @element_klass = type

      # There are a few ways to instantiate an array:
      #
      # - Array.new(4) { |i| i * i } # => [ 0, 1, 4, 9 ]
      #   In this case we can't demongoize the inputs since the values are
      #   calculated inside Array's constructor. Instead we can map over the
      #   results.
      # - Array.new([ 1, 2, 3 ]) # => [ 1, 2, 3 ]
      #   Map over and demongoize the input and pass it into the constructor.
      # - Array(3, "value") # => [ "value", "value", "value" ]
      #   Demongoize the default value and pass it into the constructor.
      # - Else, we are either instantiating an empty array or raising an error.
      #
      # Now, we could just do what we do for case 1 for all cases, but this
      # would be very inefficient in case 3, since we could be mapping over a
      # large array instead of just demongoizing one value.
      if block_given?
        super(*args, &block).map! { |x| type.demongoize(x) }
      elsif args.length == 1 && args.first.is_a?(Array)
        super(args.first.map { |x| type.demongoize(x) })
      elsif args.length == 2
        super(args.first, type.demongoize(args[1]))
      else
        super(*args, &block)
      end
    end

    # Append an item to the Array. The item will be demongoized into the
    # TypedArray's inner type.
    #
    # @example Append the item.
    #   array << item
    #
    # @param [ Object ] arg The item to append.
    #
    # @return [ Array ] The resulting array.
    def <<(arg)
      super(element_klass.demongoize(arg))
    end

    # Push item(s) to the Array. The item will be demongoized into the
    # TypedArray's inner type.
    #
    # @example Push the item.
    #   array.push(item)
    #
    # @param [ Object... ] *args The items to push.
    #
    # @return [ Array ] The resulting array.
    def push(*args)
      super(*demongoize_with_array(args))
    end
    alias :append :push

    # Prepend item(s) to the Array. The item will be demongoized into the
    # TypedArray's inner type.
    #
    # @example Prepend the item.
    #   array.unshift(item)
    #
    # @param [ Object... ] *args The items to prepend.
    #
    # @return [ Array ] The resulting array.
    def unshift(*args)
      super(*demongoize_with_array(args))
    end
    alias :prepend :unshift

    # Insert item(s) into the Array. The item will be demongoized into the
    # TypedArray's inner type.
    #
    # @example Insert an item.
    #   array.insert(1, item)
    #
    # @param [ Object... ] *args The index and the items to insert.
    #
    # @return [ Array ] The resulting array.
    def insert(*args)
      return super if args.length == 0
      super(args.first, *demongoize_with_array(args[1, args.length-1]))
    end

    # Fill the Array with item(s). The item will be demongoized into the
    # TypedArray's inner type.
    #
    # @example Fill the array.
    #   array.fill(1, 1..2)
    #   array.fill(1, 1, 2)
    #   array.fill { |i| i * i }
    #   array.fill(1) { |i| i * i }
    #
    # @param [ Object... ] *args The item to fill and the indeces to fill it into.
    #
    # @return [ Array ] The resulting array.
    def fill(*args)
      return super if args.length == 0

      if block_given?
        super.map! { |x| element_klass.demongoize(x) }
      else
        super(element_klass.demongoize(args.first), *args[1, args.length-1])
      end
    end

    # Replace the contents of this array with the new array.
    #
    # @example Replace the array.
    #   array.replace([1, 2, 3])
    #
    # @param [ Array ] arg The array to replace.
    #
    # @return [ Array ] The resulting array.
    def replace(arg)
      super(demongoize_only_array(arg))
    end

    # Concat the given arrays with this array.
    #
    # @example Concat the array.
    #   array.concat([1, 2, 3])
    #
    # @param [ Array... ] *args The arrays to concat.
    #
    # @return [ Array ] The resulting array.
    def concat(*args)
      super(*args.map(&method(:demongoize_only_array)))
    end

    # Set the element as the given index.
    #
    # @param [ Object ] *args The arguments.
    #
    # @return [ Object ] The assigned value.
    def []=(*args)
      super(*demongoize_bracket_args(args))
    end

    private

    # Given a type and an array, return a new array with all of the elements
    # demongoized with the given type.
    #
    # @param [ Class ] type The type to use for demongoization.
    # @param [ Array ] array The array to demongoize.
    #
    # @return [ Array ] The demongoized array.
    #
    # @api private
    def demongoize_with_type(type, array)
      case array
      when ::Array, ::Set
        array.map { |o| type.demongoize(o) }
      end
    end

    # Given the arguments to the Array#[]= demongoize the correct argument to
    # the TypedArray's inner type.
    #
    # There are three types of arguments to that method:
    #
    #   1. array[index] = object
    #   2. array[start..end] = object or [ object ]
    #   3. array[start, end] = object or [ object ]
    #
    # In each case we want to demongoize only the last argument, however,
    # depending on the first one or two arguments, we may want to map over an
    # array and demongoize each inner element, rather than demongoizing the array
    # itself.
    #
    # @param [ Array ] args The arguments to []=.
    #
    # @return [ Array ] The arguments with the correct argument demongoized.
    #
    # @api private
    def demongoize_bracket_args(args)
      args = args.dup
      if args.length == 2
        last = args.last
        args[-1] = if args.first.is_a?(Range)
          demongoize_with_array(last)
        else
          element_klass.demongoize(last)
        end
      elsif args.length == 3
        args[-1] = demongoize_with_array(args.last)
      end
      args
    end

    # If the given object is an array, demongoize each element in the array,
    # if it isn't demongoize the individual element.
    #
    # @param [ Array | Object ] object The object to be demongoized.
    #
    # @return [ Array | Object ] The demongoized object.
    #
    # @api private
    def demongoize_with_array(object)
      if object.is_a?(Array)
        object.map { |x| element_klass.demongoize(x) }
      else
        element_klass.demongoize(object)
      end
    end

    # If the given object is an array, demongoize each element in the array,
    # if it isn't, return the individual element.
    #
    # @param [ Array | Object ] object The object to be demongoized.
    #
    # @return [ Array | Object ] The demongoized object or the given object.
    #
    # @api private
    def demongoize_only_array(object)
      if object.is_a?(Array)
        object.map { |x| element_klass.demongoize(x) }
      else
        object
      end
    end
  end
end
