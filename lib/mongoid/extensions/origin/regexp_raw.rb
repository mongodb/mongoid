module Origin
  module Extensions

    # This module contains additional bson raw regex behaviour.
    module Regexp

      module Raw

        # Is the object a regexp?
        #
        # @example Is the object a regex?
        #   bson_raw_regexp.regexp?
        #
        # @return [ true ] Always true.
        #
        # @since 5.2.1
        def regexp?; true; end

        module ClassMethods

          # Evolve the object into a raw bson regex.
          #
          # @example Evolve the object to a regex.
          #   BSON::Regexp::Raw.evolve("^[123]")
          #
          # @param [ BSON::Regexp::Raw, String ] object The object to evolve.
          #
          # @return [ BSON::Regexp::Raw ] The evolved raw regex.
          #
          # @since 5.2.1
          def evolve(object)
            __evolve__(object) do |obj|
              obj.is_a?(String) ? BSON::Regexp::Raw.new(obj) : obj
            end
          end
        end
      end
    end
  end
end

BSON::Regexp::Raw.__send__(:include, Origin::Extensions::Regexp::Raw)
BSON::Regexp::Raw.__send__(:extend, Origin::Extensions::Regexp::Raw::ClassMethods)
