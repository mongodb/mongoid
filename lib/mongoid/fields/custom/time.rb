# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Custom #:nodoc:

      # Defines the behaviour for date fields.
      class Time
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
      end
    end
  end
end
