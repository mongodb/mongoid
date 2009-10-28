module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Float #:nodoc:
      module Conversions #:nodoc:
        def cast(value)
          value.to_f
        end
      end
    end
  end
end
