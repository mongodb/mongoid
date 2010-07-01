# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Integer #:nodoc:
      module Conversions #:nodoc:
        def set(value)
          return nil if value.blank?
          begin
            Integer(value)
          rescue ArgumentError => e
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
