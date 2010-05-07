# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Time #:nodoc:
      module Conversions #:nodoc:
        def set(value)
          return nil if value.blank?
          time = convert_to_time(value)
          strip_milliseconds(time).utc
        end

        def get(value)
          return nil if value.blank?
          value.in_time_zone(Mongoid::Config.instance.time_zone)
        end

        private

        def strip_milliseconds(time)
          ::Time.at(time.to_i)
        end

        def convert_to_time(value)
          case value
            when String then ::Time.parse(value)
            when ::Date then ::Time.utc(value.year, value.month, value.day)
            else value
          end
        end
      end
    end
  end
end
