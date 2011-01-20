# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Hash #:nodoc:
      module Conversions #:nodoc:
        extend ActiveSupport::Concern

        module ClassMethods #:nodoc:
          def get(value)
            value
          end
          def set(value)
            value
          end
        end
      end
    end
  end
end
