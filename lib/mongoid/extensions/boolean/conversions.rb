# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Boolean #:nodoc:
      module Conversions #:nodoc:
        BOOLEAN_MAP = {true => true, "true" => true, "TRUE" => true, "1" => true, 1 => true, 1.0 => true}
        def set(value)
          BOOLEAN_MAP.include?(value)
        end
        def get(value)
          value
        end
      end
    end
  end
end
