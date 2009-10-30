module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Time #:nodoc:
      module Conversions #:nodoc:
        def set(value)
          value.to_time
        end
        def get(value)
          value
        end
      end
    end
  end
end
