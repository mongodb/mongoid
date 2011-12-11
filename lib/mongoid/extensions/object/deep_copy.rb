# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Object #:nodoc:
      module DeepCopy #:nodoc:

        # Make a deep copy of the object.
        #
        # @example Make a deep copy.
        #   "testing"._deep_copy
        #
        # @return [ Object ] The deep copy.
        #
        # @since 2.4.0
        def _deep_copy
          duplicable? ? dup : self
        end
      end
    end
  end
end
