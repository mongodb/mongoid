module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Date #:nodoc:
      module Conversions #:nodoc:
        def set(value)
          value.to_time.utc
        end
        def get(value)
          value ? value.to_date : value
        end
      end
    end
  end
end
