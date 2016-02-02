# encoding: utf-8
module Origin
  module Extensions

    # This module contains additional time behaviour.
    module Time

      # Evolve the time as a date, UTC midnight.
      #
      # @example Evolve the time to a date query format.
      #   time.__evolve_date__
      #
      # @return [ Time ] The date at midnight UTC.
      #
      # @since 1.0.0
      def __evolve_date__
        ::Time.utc(year, month, day, 0, 0, 0, 0)
      end

      # Evolve the time into a utc time.
      #
      # @example Evolve the time.
      #   time.__evolve_time__
      #
      # @return [ Time ] The time in UTC.
      #
      # @since 1.0.0
      def __evolve_time__
        utc
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

::Time.__send__(:include, Origin::Extensions::Time)
::Time.__send__(:extend, Origin::Extensions::Time::ClassMethods)
