# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Symbol#:nodoc:
      # This module converts objects into mongoid related objects.
      module Conversions #:nodoc:
        extend ActiveSupport::Concern

        module ClassMethods
          def set(value)
            (value.nil? or (value.respond_to?(:empty?) && value.empty?)) ? nil : value.to_sym
          end

          def get(value)
            value
          end
        end
      end
    end
  end
end
