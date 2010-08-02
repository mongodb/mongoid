# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module ObjectID #:nodoc:
      module Conversions #:nodoc:
        def set(value)
          if value.is_a?(::String)
            BSON::ObjectID.from_string(value)
          else
            value
          end
        end
        def get(value)
          value
        end
      end
    end
  end
end
