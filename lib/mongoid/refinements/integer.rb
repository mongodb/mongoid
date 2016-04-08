module Mongoid
  module Refinements

    refine Integer do

      # Returns the integer as a time.
      #
      # @example Convert the integer to a time.
      #   1335532685.mongoize_time
      #
      # @return [ Time ] The converted time.
      #
      # @since 6.0.0
      def mongoize_time
        ::Time.at(self)
      end

      # Is the integer a number?
      #
      # @example Is the object a number?.
      #   object.numeric?
      #
      # @return [ true ] Always true.
      #
      # @since 6.0.0
      def numeric?
        true
      end

      # Is the object not to be converted to bson on criteria creation?
      #
      # @example Is the object unconvertable?
      #   object.unconvertable_to_bson?
      #
      # @return [ true ] If the object is unconvertable.
      #
      # @since 6.0.0
      def unconvertable_to_bson?
        true
      end

      # Evolve the numeric value into a mongo friendly date, aka UTC time at
      # midnight.
      #
      # @example Evolve to a date.
      #   125214512412.1123.__evolve_date__
      #
      # @return [ Time ] The time representation at UTC midnight.
      #
      # @since 1.0.0
      def __evolve_date__
        time = ::Time.at(self).utc
        ::Time.utc(time.year, time.month, time.day, 0, 0, 0, 0)
      end

      # Evolve the numeric value into a mongo friendly time.
      #
      # @example Evolve to a time.
      #   125214512412.1123.__evolve_time__
      #
      # @return [ Time ] The time representation.
      #
      # @since 1.0.0
      def __evolve_time__
        ::Time.at(self).utc
      end

      # Get the integer as a sort direction.
      #
      # @example Get the integer as a sort direction.
      #   1.to_direction
      #
      # @return [ Integer ] self.
      #
      # @since 1.0.0
      def to_direction; self; end
    end

    refine Integer.singleton_class do

      # Turn the object from the ruby type we deal with to a Mongo friendly
      # type.
      #
      # @example Mongoize the object.
      #   BigDecimal.mongoize("123.11")
      #
      # @return [ String ] The object mongoized.
      #
      # @since 6.0.0
      def mongoize(object)
        unless object.blank?
          __numeric__(object).to_i rescue 0
        else
          nil
        end
      end
      alias :demongoize :mongoize

      # Get the object as a numeric.
      #
      # @api private
      #
      # @example Get the object as numeric.
      #   Object.__numeric__("1.442")
      #
      # @param [ Object ] object The object to convert.
      #
      # @return [ Object ] The converted number.
      #
      # @since 1.0.0
      def __numeric__(object)
        object.to_s =~ /(^[-+]?[0-9]+$)|(\.0+$)|(\.$)/ ? object.to_i : Float(object)
      end

      # Evolve the object to an integer.
      #
      # @example Evolve to integers.
      #   Integer.evolve("1")
      #
      # @param [ Object ] object The object to evolve.
      #
      # @return [ Integer ] The evolved object.
      #
      # @since 1.0.0
      def evolve(object)
        __evolve__(object) do |obj|
          __numeric__(obj) rescue obj
        end
      end
    end
  end
end