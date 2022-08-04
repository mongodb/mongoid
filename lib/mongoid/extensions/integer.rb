# frozen_string_literal: true

module Mongoid
  module Extensions
    module Integer

      # Converts the integer into a time as the number of seconds since the epoch.
      #
      # @example Convert the integer to a time.
      #   1335532685.__mongoize_time__
      #
      # @return [ Time | ActiveSupport::TimeWithZone ] The time.
      def __mongoize_time__
        ::Time.configured.at(self)
      end

      # Is the integer a number?
      #
      # @example Is the object a number?.
      #   object.numeric?
      #
      # @return [ true ] Always true.
      def numeric?
        true
      end

      # Is the object not to be converted to bson on criteria creation?
      #
      # @example Is the object unconvertable?
      #   object.unconvertable_to_bson?
      #
      # @return [ true ] If the object is unconvertable.
      def unconvertable_to_bson?
        true
      end

      module ClassMethods

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   BigDecimal.mongoize("123.11")
        #
        # @return [ Integer | nil ] The object mongoized or nil.
        def mongoize(object)
          return if object.blank?
          if object.is_a?(String)
            if object.numeric?
              object.to_i
            end
          else
            object.try(:to_i)
          end
        end
        alias :demongoize :mongoize
      end
    end
  end
end

::Integer.__send__(:include, Mongoid::Extensions::Integer)
::Integer.extend(Mongoid::Extensions::Integer::ClassMethods)
