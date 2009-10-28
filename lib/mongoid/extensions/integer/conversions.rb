module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Integer #:nodoc:
      module Conversions #:nodoc:
        def cast(value)
          value.to_i
        end
      end
    end
  end
end
