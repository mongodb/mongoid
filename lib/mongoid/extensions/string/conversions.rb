# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module String #:nodoc:
      module Conversions #:nodoc:
        extend ActiveSupport::Concern

        # Convert the string to an array with the string in it.
        #
        # Example:
        #
        # <tt>"Testing".to_a</tt>
        #
        # Returns:
        #
        # An array with only the string in it.
        def to_a
          [ self ]
        end

        module ClassMethods #:nodoc:

          def get(value)
            value
          end

          def set(value)
            value.to_s unless value.nil?
          end
        end
      end
    end
  end
end
