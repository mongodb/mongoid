# encoding: utf-8
module Mongoid #:nodoc:
  module Fields #:nodoc:
    module Serializable #:nodoc:
      # Defines the behaviour for hash fields.
      class Hash
        include Serializable

        # Get the default value for the field. If the default is a proc call
        # it, otherwise clone the array.
        #
        # @example Get the default.
        #   field.default
        #
        # @return [ Object ] The default value.
        #
        # @since 2.1.0
        def default
          return nil unless default_value
          default_value.respond_to?(:call) ? default_value.call : default_value.dup
        end
      end
    end
  end
end
