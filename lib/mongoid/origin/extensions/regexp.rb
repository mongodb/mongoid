# encoding: utf-8
module Origin
  module Extensions

    # This module contains additional regex behaviour.
    module Regexp

      # Is the object a regexp?
      #
      # @example Is the object a regex?
      #   /^[123]/.regexp?
      #
      # @return [ true ] Always true.
      #
      # @since 1.0.0
      def regexp?; true; end

      module ClassMethods

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
end

::Regexp.__send__(:include, Origin::Extensions::Regexp)
::Regexp.__send__(:extend, Origin::Extensions::Regexp::ClassMethods)
