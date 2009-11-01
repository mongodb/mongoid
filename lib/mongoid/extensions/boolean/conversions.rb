module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Boolean #:nodoc:
      module Conversions #:nodoc:
        def set(value)
          value.to_s == "true"
        end
        def get(value)
          value
        end
      end
    end
  end
end
