# encoding: utf-8
module Origin
  module Extensions

    # This module contains additional datetime behaviour.
    module DateTime

      # Evolve the date time into a mongo friendly UTC time.
      #
      # @example Evolve the date time.
      #   date_time.__evolve_time__
      #
      # @return [ Time ] The converted time in UTC.
      #
      # @since 1.0.0
      def __evolve_time__
        usec = strftime("%6N").to_f
        if utc?
          ::Time.utc(year, month, day, hour, min, sec, usec)
        else
          ::Time.local(year, month, day, hour, min, sec, usec).utc
        end
      end

      module ClassMethods

        # Evolve the object to an date.
        #
        # @example Evolve dates.
        #
        # @example Evolve string dates.
        #
        # @example Evolve date ranges.
        #
        # @param [ Object ] object The object to evolve.
        #
        # @return [ Time ] The evolved date time.
        #
        # @since 1.0.0
        def evolve(object)
          object.__evolve_time__
        end
      end
    end
  end
end

::DateTime.__send__(:include, Origin::Extensions::DateTime)
::DateTime.__send__(:extend, Origin::Extensions::DateTime::ClassMethods)
