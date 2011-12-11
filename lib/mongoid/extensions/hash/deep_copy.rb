# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Hash #:nodoc:
      module DeepCopy #:nodoc:

        # Make a deep copy of the hash.
        #
        # @example Make a deep copy.
        #   { :test => "value" }._deep_copy
        #
        # @return [ Hash ] The deep copy.
        #
        # @since 2.4.0
        def _deep_copy
          {}.tap do |copy|
            each_pair do |key, value|
              copy[key] = value._deep_copy
            end
          end
        end
      end
    end
  end
end
