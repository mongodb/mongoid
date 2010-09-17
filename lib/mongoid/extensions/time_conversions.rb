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
        value = value.getlocal unless Mongoid::Config.instance.use_utc?
        if Mongoid::Config.instance.use_activesupport_time_zone?
          time_zone = Mongoid::Config.instance.use_utc? ? 'UTC' : Time.zone
          value = value.in_time_zone(time_zone)
        end
        value
      end

      protected

      def strip_milliseconds(time)
        ::Time.at(time.to_i)
      end

      def convert_to_time(value)
        case value
          when ::String then (Mongoid::Config.instance.use_activesupport_time_zone? ? ::Time.zone : ::Time).parse(value)
          when ::DateTime 
            if Mongoid::Config.instance.use_activesupport_time_zone?
              ::Time.zone.local(value.year, value.month, value.day, value.hour, value.min, value.sec)
            else
              ::Time.utc(value.year, value.month, value.day, value.hour, value.min, value.sec)
            end
          when ::Date
            if Mongoid::Config.instance.use_activesupport_time_zone?
              ::Time.zone.local(value.year, value.month, value.day)
            else
              ::Time.utc(value.year, value.month, value.day)
            end
          else value
        end
      end
    end
  end
end
