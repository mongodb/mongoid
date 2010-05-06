# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module DateTime #:nodoc:
      module Conversions #:nodoc:
        def get(value)
          super.try(:to_datetime)
        end
      end
    end
  end
end
