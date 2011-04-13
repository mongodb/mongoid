# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Range #:nodoc:
      module Conversions #:nodoc:
        extend ActiveSupport::Concern

        def to_hash
          { "min" => min, "max" => max }
        end

        module ClassMethods #:nodoc:

          def get(value)
            value.nil? ? nil : ::Range.new(value["min"], value["max"])
          end

          def set(value)
            value.nil? ? nil : value.to_hash
          end
        end
      end
    end
  end
end
