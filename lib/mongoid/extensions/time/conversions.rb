module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Time #:nodoc:
      module Conversions #:nodoc:
        def set(value)
          ::Time.parse(value.to_s).utc
        end
        def get(value)
          ::Time.zone ? ::Time.zone.parse(value.to_s).getlocal : value
        end
      end
    end
  end
end
