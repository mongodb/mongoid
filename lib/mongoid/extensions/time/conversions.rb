# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Time #:nodoc:
      module Conversions #:nodoc:
        def set(value)
          return nil if value.blank?
          time = ::Time.parse(value.is_a?(::Time) ? value.strftime("%Y-%m-%d %H:%M:%S %Z") : value.to_s)
          time.utc? ? time : time.utc
        end
        def get(value)
          return nil if value.blank?
          ::Time.zone ? value.getlocal : value
        end
      end
    end
  end
end
