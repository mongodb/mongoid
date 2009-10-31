module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Time #:nodoc:
      module Conversions #:nodoc:
        def set(value)
          ::Time.parse(value.to_s).utc
        end
        def get(value)
          value
        end
      end
    end
  end
end
