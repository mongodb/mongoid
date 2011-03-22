# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Range #:nodoc:
      # This module converts set into mongoid related objects.
      module Conversions #:nodoc:
        extend ActiveSupport::Concern

        module ClassMethods #:nodoc:
          def get(value)
            value.nil? ? nil : ::Range.new(value["min"], value["max"])
          end
          def set(value)
            value.nil? ? nil : value.to_hash
          end
        end
        
        module InstanceMethods
          def to_hash
            {"min" => min, "max" => max}
          end
        end
      end
    end
  end
end
