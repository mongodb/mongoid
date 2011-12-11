# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Array #:nodoc:
      module DeepCopy #:nodoc:

        # Make a deep copy of the array.
        #
        # @example Make a deep copy.
        #   [ 1, 2, 3 ]._deep_copy
        #
        # @return [ Array ] The deep copy.
        #
        # @since 2.4.0
        def _deep_copy
          [].tap do |copy|
            each do |value|
              copy.push(value._deep_copy)
            end
          end
        end
      end
    end
  end
end
