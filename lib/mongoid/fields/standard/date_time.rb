# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Standard #:nodoc:

      # Defines the behaviour for date time fields.
      class DateTime
        include Definable
        include Timekeeping

        # When reading the field do we need to cast the value? This holds true when
        # times are stored or for big decimals which are stored as strings.
        #
        # @example Typecast on a read?
        #   field.cast_on_read?
        #
        # @return [ true ] DateTime fields cast on read.
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
        # @return [ DateTime ] The converted date time.
        #
        # @since 2.1.0
        def deserialize(object)
          object.try(:to_datetime)
        end
        alias :get :deserialize
      end
    end
  end
end
