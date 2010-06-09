# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Hash #:nodoc:
      module Conversions #:nodoc:
        extend ActiveSupport::Concern

        # Get the difference between 2 hashes. This will give back a new hash
        # with the keys and pairs of [ old, new ] values.
        #
        # Example:
        #
        #   first = { :field => "value" }
        #   second = { :field => "new" }
        #   first.difference(second) # => { :field => [ "value", "new" ] }
        #
        # Returns:
        #
        # A +Hash+ of modifications.
        def difference(other)
          changes = {}
          each_pair do |key, value|
            if other.has_key?(key)
              new_value = other[key]
              changes[key] = [ value, new_value ] if new_value != value
            end
          end
          changes
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
