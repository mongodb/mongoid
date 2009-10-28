module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Integer #:nodoc:
      module Conversions #:nodoc:
        def cast(value)
          value =~ /\d/ ? value.to_i : value
        end
      end
    end
  end
end
