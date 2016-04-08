module Mongoid
  module Refinements

    refine Regexp do

      # Is the object a regexp?
      #
      # @example Is the object a regex?
      #   /^[123]/.regexp?
      #
      # @return [ true ] Always true.
      #
      # @since 1.0.0
      def regexp?; true; end
    end

    refine Regexp.singleton_class do

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   Regexp.mongoize(/^[abc]/)
      #
      # @param [ Regexp, String ] object The object to mongoize.
      #
      # @return [ Regexp ] The object mongoized.
      #
      # @since 6.0.0
      def mongoize(object)
        ::Regexp.new(object)
      end

      # Evolve the object into a regex.
      #
      # @example Evolve the object to a regex.
      #   Regexp.evolve("^[123]")
      #
      # @param [ Regexp, String ] object The object to evolve.
      #
      # @return [ Regexp ] The evolved regex.
      #
      # @since 1.0.0
      def evolve(object)
        __evolve__(object) do |obj|
          ::Regexp.new(obj)
        end
      end
    end
  end
end