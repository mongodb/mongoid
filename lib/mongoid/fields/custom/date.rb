# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Custom #:nodoc:

      # Defines the behaviour for date fields.
      class Date
        include Definable
        include Timekeeping

        # When reading the field do we need to cast the value? This holds true when
        # times are stored or for big decimals which are stored as strings.
        #
        # @example Typecast on a read?
        #   field.cast_on_read?
        #
        # @return [ true ] Date fields cast on read.
        #
        # @since 2.1.0
        def cast_on_read?; true; end

        # Deserialize this field from the type stored in MongoDB to the type
        # defined on the model.
        #
        # @example Deserialize the field.
        #   field.deserialize(object)
        #
        # @param [ Object ] object The object to cast.
        #
        # @return [ Date ] The converted date.
        #
        # @since 2.1.0
        def deserialize(object)
         return nil if object.blank?
          if Mongoid::Config.use_utc?
            object.to_date
          else
            ::Date.new(object.year, object.month, object.day)
          end
        end
        alias :get :deserialize

        protected

        # Converts the date to a time to persist.
        #
        # @example Convert the date to a time.
        #   Date.convert_to_time(date)
        #
        # @param [ Date ] value The date to convert.
        #
        # @return [ Time ] The date converted.
        #
        # @since 2.1.0
        def convert_to_time(value)
          value = ::Date.parse(value) if value.is_a?(::String)
          value = ::Date.civil(*value) if value.is_a?(::Array)
          ::Time.utc(value.year, value.month, value.day)
        end
      end
    end
  end
end
