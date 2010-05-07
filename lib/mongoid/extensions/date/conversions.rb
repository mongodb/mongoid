# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Date #:nodoc:
      module Conversions #:nodoc:
        def get(value)
          return nil if value.blank?
          if Mongoid::Config.instance.time_zone.nil?
            ::Date.new(value.year, value.month, value.day)
          else
            Mongoid::Config.instance.time_zone.local(value.year, value.month, value.day).to_date
          end
        end

        protected

        def convert_to_time(value)
          value = ::Date.parse(value) if value.is_a?(::String)
          ::Time.utc(value.year, value.month, value.day)
        end
      end
    end
  end
end
