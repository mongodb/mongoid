module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module TimeConversions #:nodoc:
      def set(value)
        return nil if value.blank?
        time = convert_to_time(value)
        strip_milliseconds(time).utc
      end

      def get(value)
        return nil if value.blank?
        if Mongoid::Config.instance.time_zone.nil?
          value.getlocal
        else
          value.in_time_zone(Mongoid::Config.instance.time_zone)
        end
      end

      protected

      def strip_milliseconds(time)
        ::Time.at(time.to_i)
      end

      def convert_to_time(value)
        case value
          when ::String then ::Time.parse(value)
          when ::DateTime then ::Time.utc(value.year, value.month, value.day, value.hour, value.min, value.sec)
          when ::Date then ::Time.utc(value.year, value.month, value.day)
          else value
        end
      end
    end
  end
end