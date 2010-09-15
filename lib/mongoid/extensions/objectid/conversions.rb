# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module ObjectId #:nodoc:
      module Conversions #:nodoc:
        def set(value)
          value
        end
        def get(value)
          value
        end
      end
    end
  end
end
