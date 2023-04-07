# frozen_string_literal: true

module Mongoid
  class Criteria

    # This is a helper module for translating atomic and composite
    # Ruby values into corresponding query and option components.
    # Originally implemented as patches to core classes, that approach
    # has generally fallen into disfavor, as it bleeds too much into
    # the public namespace.
    #
    # @api private
    module Translator
      extend self

      # Converts the given value to a direction specification for use in
      # sorting.
      #
      # @example Convert the value to a direction.
      #   Translator.to_direction(:desc)
      #   Translator.to_direction("1")
      #   Translator.to_direction(-1)
      #   Translator.to_direction(score: { "$meta": "textScore" })
      #
      # @param [ Hash | Numeric | String | Symbol ] value The value to convert.
      #
      # @return [ Hash | Numeric ] The direction.
      def to_direction(value)
        case value
        when Hash then
          value
        when Numeric then
          value
        when String then
          value =~ /desc/i ? -1 : 1
        when Symbol then
          to_direction(value.to_s)
        else
          raise ArgumentError, "cannot translate #{value.inspect} (#{value.class}) to a direction specification"
        end
      end
    end

  end
end
