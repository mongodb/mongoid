# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Object #:nodoc:

      # This module has object checks in it.
      module Checks #:nodoc:
        attr_accessor :unconvertable_to_bson

        # Since Active Support's blank? check looks to see if the object
        # responds to #empty? and will call it if it does, we need another way
        # to check if the object is empty or nil in case the user has defined a
        # field called "empty" on the document.
        #
        # @example Is the array vacant?
        #   [].vacant?
        #
        # @example Is the hash vacant?
        #   {}.vacant?
        #
        # @example Is the object vacant?
        #   nil.vacant?
        #
        # @return [ true, false ] True if empty or nil, false if not.
        #
        # @since 2.0.2
        def _vacant?
          is_a?(::Enumerable) || is_a?(::String) ? empty? : !self
        end

        # Is the object not to be converted to bson on criteria creation?
        #
        # @example Is the object unconvertable?
        #   object.unconvertable_to_bson?
        #
        # @return [ true, false ] If the object is unconvertable.
        #
        # @since 2.2.1
        def unconvertable_to_bson?
          !!@unconvertable_to_bson
        end
      end
    end
  end
end
