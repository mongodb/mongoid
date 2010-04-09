# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Time #:nodoc:
      module Conversions #:nodoc:
        def set(value)
          return nil if value.blank?
          time = convertable?(value) ? value.to_time : ::Time.parse(value.to_s)
          # Convert time to milliseconds since BSON stores dates with that accurracy, but Ruby uses microseconds
          ::Time.at((time.to_f * 1000).round / 1000.0).utc if time
        rescue ArgumentError
          value
        end
        def get(value)
          return nil if value.blank?
          ::Time.zone ? value.getlocal : value
        end

        protected
        def convertable?(value)
          value.is_a?(::Time) || value.is_a?(::Date) || value.is_a?(::DateTime)
        end
      end
    end
  end
end
