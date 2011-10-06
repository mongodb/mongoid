# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module String #:nodoc:

      # This module has object checks in it.
      module Checks #:nodoc:
        attr_accessor :unconvertable_to_bson

        # Is the string a valid value for a Mongoid id?
        #
        # @example Is the string an id value?
        #   "_id".mongoid_id?
        #
        # @return [ true, false ] If the string is id or _id.
        #
        # @since 2.3.1
        def mongoid_id?
          self =~ /^(|_)id$/
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
