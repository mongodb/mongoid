module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Date #:nodoc:
      module Conversions #:nodoc:
        def set(value)
          value.to_time.utc
        end
        def get(value)
          value.to_date
        end
      end
    end
  end
end
