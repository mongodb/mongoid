# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module DateTime #:nodoc:
      module Conversions #:nodoc:
        def set(value)
          return nil if value.blank?
          ::DateTime.parse(value.to_s).utc
        end
        def get(value)
          return nil if value.blank?
          ::Time.zone ? ::Time.parse(value.to_s).getlocal.to_datetime : value.to_datetime
        end
      end
    end
  end
end
