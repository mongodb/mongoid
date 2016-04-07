module Mongoid
  module Refinements

    refine TrueClass do

      # Get the value of the object as a mongo friendy sort value.
      #
      # @example Get the object as sort criteria.
      #   true.sortable
      #
      # @return [ Integer ] 1.
      #
      # @since 6.0.0
      def sortable
        1
      end

      # Is the passed value a boolean?
      #
      # @example Is the value a boolean type?
      #   true.is_a?(Boolean)
      #
      # @param [ Class ] other The class to check.
      #
      # @return [ true, false ] If the other is a boolean.
      #
      # @since 6.0.0
      def is_a?(other)
        if other == ::Boolean || other.class == ::Boolean
          return true
        end
        super(other)
      end
    end
  end
end