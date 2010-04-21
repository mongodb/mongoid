# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Object #:nodoc:
      # This module converts objects into mongoid related objects.
      module Conversions #:nodoc:
        extend ActiveSupport::Concern
        module InstanceMethods
          # Converts this object to a hash of attributes
          def mongoidize
            self.attributes
          end
        end

        module ClassMethods
          def set(value)
            value.respond_to?(:attributes) ? value.attributes : value
          end

          def get(value)
            value ? self.new(value) : value
          end
        end
      end
    end
  end
end
