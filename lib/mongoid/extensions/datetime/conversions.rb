# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module DateTime #:nodoc:
      module Conversions #:nodoc:
        def set(value)
            return nil if value.blank?
            time = (value.is_a?(::DateTime) || value.is_a?(::Time)) ? value.to_time : ::Time.parse(value.to_s)
            # Convert time to milliseconds since BSON stores dates with that accurracy, but Ruby uses microseconds
            ::Time.at((time.to_f * 1000).round / 1000.0).utc if time
          rescue ArgumentError
            value
        end
        def get(value)
          return nil if value.blank?
          ::Time.zone ? value.getlocal.to_datetime : value
        end
      end
    end
  end
end
