# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Integer #:nodoc:
      module Conversions #:nodoc:
        def set(value)
          value =~ /\d/ ? value.to_i : value
        end
        def get(value)
          value
        end
      end
    end
  end
end
