# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Array #:nodoc:

      # This module converts arrays into mongoid related objects.
      module Conversions #:nodoc:
        extend ActiveSupport::Concern

        module ClassMethods #:nodoc:

          # If the value is not an array or nil we will raise an error,
          # otherwise return the value.
          #
          # @example Raise or return the value.
          #   Array.raise_or_return([])
          #
          # @param [ Object ] value The value to check.a
          #
          # @raise [ InvalidType ] If not passed an array.
          #
          # @return [ Array ] The array.
          #
          # @since 1.0.0
          def raise_or_return(value)
            unless value.nil? || value.is_a?(::Array)
              raise Mongoid::Errors::InvalidType.new(::Array, value)
            end
            value
          end
          alias :get :raise_or_return
          alias :set :raise_or_return
        end
      end
    end
  end
end
