# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module String #:nodoc:
      module Conversions #:nodoc:
        def set(value)
          value.to_s
        end
        def get(value)
          value
        end
      end
    end
  end
end
