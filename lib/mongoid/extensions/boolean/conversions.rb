module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Boolean #:nodoc:
      module Conversions #:nodoc:
        def cast(value)
          return true if value == "true"
          false
        end
      end
    end
  end
end
