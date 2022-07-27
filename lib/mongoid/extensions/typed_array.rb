# frozen_string_literal: true

module Mongoid
  class TypedArray < ::Array

    attr_reader :element_klass

    # Initialize a typed array. Set the element klass and mongoizes all of the
    # elements in the given array.
    #
    # @param [ Class ] type The inner type of the array.
    # @param [ Array ] array The array.
    def initialize(type, *args, &block)
      @element_klass = type
      super(*args, &block).map! { |x| type.mongoize(x) }
    end

    # Append an item to the Array. The item will be mongoized into the
    # TypedArray's inner type.
    #
    # @example Append the item.
    #   array << item
    #
    # @param [ Object ] arg The item to append.
    #
    # @return [ Array ] The resulting array.
    def <<(arg)
      super(element_klass.mongoize(arg))
    end

    # Push item(s) to the Array. The item will be mongoized into the
    # TypedArray's inner type.
    #
    # @example Push the item.
    #   array.push(item)
    #
    # @param [ Object... ] *args The items to push.
    #
    # @return [ Array ] The resulting array.
    def push(*args)
      super(*mongoize_with_array(args))
    end
    alias :append :push

    # Prepend item(s) to the Array. The item will be mongoized into the
    # TypedArray's inner type.
    #
    # @example Prepend the item.
    #   array.unshift(item)
    #
    # @param [ Object... ] *args The items to prepend.
    #
    # @return [ Array ] The resulting array.
    def unshift(*args)
      super(*mongoize_with_array(args))
    end
    alias :prepend :unshift

    # Insert item(s) into the Array. The item will be mongoized into the
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
      super(args.first, *mongoize_with_array(args[1, args.length-1]))
    end

    # Fill the Array with item(s). The item will be mongoized into the
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
        super.map! { |x| element_klass.mongoize(x) }
      else
        super(element_klass.mongoize(args.first), *args[1, args.length-1])
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
      super(mongoize_with_array(arg))
    end

    # Set the element as the given index.
    #
    # @param [ Object ] *args The arguments.
    #
    # @return [ Object ] The assigned value.
    def []=(*args)
      super(*mongoize_bracket_args(args))
    end

    private

    # Given a type and an array, return a new array with all of the elements
    # mongoized with the given type.
    #
    # @param [ Class ] type The type to use for mongoization.
    # @param [ Array ] array The array to mongoize.
    #
    # @return [ Array ] The mongoized array.
    #
    # @api private
    def mongoize_with_type(type, array)
      case array
      when ::Array, ::Set
        array.map { |o| type.mongoize(o) }
      end
    end

    # Given the arguments to the Array#[]= mongoize the correct argument to
    # the TypedArray's inner type.
    #
    # There are three types of arguments to that method:
    #
    #   1. array[index] = object
    #   2. array[start..end] = object or [ object ]
    #   3. array[start, end] = object or [ object ]
    #
    # In each case we want to mongoize only the last argument, however,
    # depending on the first one or two arguments, we may want to map over an
    # array and mongoize each inner element, rather than mongoizing the array
    # itself.
    #
    # @param [ Array ] args The arguments to []=.
    #
    # @return [ Array ] The arguments with the correct argument mongoized.
    #
    # @api private
    def mongoize_bracket_args(args)
      args = args.dup
      if args.length == 2
        last = args.last
        args[-1] = if args.first.is_a?(Range)
          mongoize_with_array(last)
        else
          element_klass.mongoize(last)
        end
      elsif args.length == 3
        args[-1] = mongoize_with_array(args.last)
      end
      args
    end

    # If the given object is an array, mongoize each element in the array,
    # if it isn't mongoize the individual element.
    #
    # @param [ Array | Object ] object The object to be mongoized.
    #
    # @return [ Array | Object ] The mongoized object.
    #
    # @api private
    def mongoize_with_array(object)
      if object.is_a?(Array)
        object.map { |x| element_klass.mongoize(x) }
      else
        element_klass.mongoize(object)
      end
    end
  end
end
