# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Object #:nodoc:

      # This module contains reflection convenience methods.
      module Reflections
        extend ActiveSupport::Concern

        # Get the value for an instance variable or nil if it doesn't exist.
        #
        # @example Get the value for an instance var.
        #   document.ivar("person")
        #
        # @param [ String ] name The name of the variable.
        #
        # @return [ Object, nil ] The value or nil.
        #
        # @since 2.0.0.rc.1
        def ivar(name)
          if instance_variable_defined?("@#{name}")
            return instance_variable_get("@#{name}")
          end
          nil
        end
      end
    end
  end
end
