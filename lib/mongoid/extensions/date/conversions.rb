# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Date #:nodoc:
      module Conversions #:nodoc:
        def get(value)
          super.try(:to_date)
        end

        def convert_to_time(value)
          value = ::Date.parse(value) if value.is_a?(::String)
          ::Time.utc(value.year, value.month, value.day)
        end
      end
    end
  end
end
