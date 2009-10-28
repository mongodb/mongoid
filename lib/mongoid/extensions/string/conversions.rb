module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module String #:nodoc:
      module Conversions #:nodoc:
        def cast(value)
          value.to_s
        end
      end
    end
  end
end
