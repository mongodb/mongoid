# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Date #:nodoc:
      module Conversions #:nodoc:
        def set(value)
          return nil if value.blank?
          date = (value.is_a?(::Date) || value.is_a?(::Time)) ? value : ::Date.parse(value.to_s)
          ::Time.utc(date.year, date.month, date.day)
        end
        def get(value)
          value.utc.to_date if value
        end
      end
    end
  end
end
