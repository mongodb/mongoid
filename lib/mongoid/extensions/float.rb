# encoding: utf-8
module Mongoid
  module Extensions
    module Float

      # Convert the float into a time.
      #
      # @example Convert the float into a time.
      #   1335532685.117847.__mongoize_time__
      #
      # @return [ Time ] The float as a time.
      #
      # @since 3.0.0
      def __mongoize_time__
        ::Time.at(self)
      end

      # Is the float a number?
      #
      # @example Is the object a number?.
      #   object.numeric?
      #
      # @return [ true ] Always true.
      #
      # @since 3.0.0
      def numeric?
        true
      end

      module ClassMethods

        # Turn the object from the ruby type we deal with to a Mongo friendly
        # type.
        #
        # @example Mongoize the object.
        #   Float.mongoize("123.11")
        #
        # @param [ Object ] object The object to mongoize.
        #
        # @return [ String ] The object mongoized.
        #
        # @since 3.0.0
        def mongoize(object)
          unless object.blank?
            __numeric__(object).to_f rescue 0.0
          else
            nil
          end
        end
      end
    end
  end
end

::Float.__send__(:include, Mongoid::Extensions::Float)
::Float.__send__(:extend, Mongoid::Extensions::Float::ClassMethods)
