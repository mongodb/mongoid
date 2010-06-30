# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Boolean #:nodoc:
      module Conversions #:nodoc:
        extend ActiveSupport::Concern

        BOOLEAN_MAP = {
          true => true, "true" => true, "TRUE" => true, "1" => true, 1 => true, 1.0 => true,
          false => false, "false" => false, "FALSE" => false, "0" => false, 0 => false, 0.0 => false
        }

        module ClassMethods #:nodoc

          def is_a?(other)
            if other.name == "Boolean" ||
               other.name == "FalseClass" ||
               other.name == "TrueClass"
              return true
            end
            false
          end

          def set(value)
            value = BOOLEAN_MAP[value]
            value.nil? ? nil : value
          end

          def get(value)
            value
          end
        end
      end
    end
  end
end
