# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Array #:nodoc:
      # This module converts arrays into mongoid related objects.
      module Conversions #:nodoc:
        extend ActiveSupport::Concern

        module ClassMethods #:nodoc:
          def raise_or_return(value)
            raise Mongoid::Errors::InvalidType.new(::Array, value) unless value.is_a?(::Array)
            value
          end

          alias :get :raise_or_return
          alias :set :raise_or_return
        end
      end
    end
  end
end
