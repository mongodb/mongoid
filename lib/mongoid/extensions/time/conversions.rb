module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Time #:nodoc:
      module Conversions #:nodoc:
        def set(value)
          return nil if value.blank?
          ::Time.parse(value.to_s).utc
        end
        def get(value)
          return nil if value.blank?
          ::Time.zone ? ::Time.zone.parse(value.to_s).getlocal : value
        end
      end
    end
  end
end
