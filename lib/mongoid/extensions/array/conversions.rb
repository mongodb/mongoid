# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Array #:nodoc:
      # This module converts arrays into mongoid related objects.
      module Conversions #:nodoc:
        extend ActiveSupport::Concern

        module InstanceMethods #:nodoc:
          # Converts this array into an array of hashes.
          def mongoidize
            collect { |obj| obj.attributes }
          end
        end

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
