# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Float #:nodoc:
      module Conversions #:nodoc:
        def set(value)
          value.to_f
        end
        def get(value)
          value
        end
      end
    end
  end
end
