# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Set #:nodoc:
      # This module converts set into mongoid related objects.
      module Conversions #:nodoc:
        extend ActiveSupport::Concern

        module ClassMethods #:nodoc:
          def get(value)
            ::Set.new(value)
          end
          def set(value)
            value.to_a
          end
        end
      end
    end
  end
end
