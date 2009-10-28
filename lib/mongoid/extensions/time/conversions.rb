module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Time #:nodoc:
      module Conversions #:nodoc:
        def cast(value)
          value.to_time
        end
      end
    end
  end
end
