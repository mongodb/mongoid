# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Boolean #:nodoc:
      module Conversions #:nodoc:
        def set(value)
          val = value.to_s
          val == "true" || val == "1"
        end
        def get(value)
          value
        end
      end
    end
  end
end
