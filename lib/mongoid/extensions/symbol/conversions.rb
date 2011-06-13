# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Symbol #:nodoc:

      # This module converts symbols into strings.
      module Conversions
        extend ActiveSupport::Concern

        module ClassMethods #:nodoc:

          # Gets the symbol.
          #
          # @example Get the symbol.
          #   Symbol.try_bson(:test)
          #
          # @param [ Symbol ] value The symbol.
          #
          # @return [ Symbol ] The symbol untouched.
          #
          # @since 1.0.0
          def try_bson(value)
            value
          end

          # Convert the object to a symbol.
          #
          # @example Convert the object.
          #   Symbol.from_bson("test")
          #
          # @param [ String ] value The string to convert.
          #
          # @return [ Symbol ] The converted symbol.
          #
          # @since 1.0.0
          def from_bson(value)
            (value.nil? or (value.respond_to?(:empty?) && value.empty?)) ? nil : value.to_sym
          end
        end
      end
    end
  end
end
