module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Date #:nodoc:
      module Conversions #:nodoc:
        def cast(value)
          parse(value.to_s)
        end
      end
    end
  end
end
