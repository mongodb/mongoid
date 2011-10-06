# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Symbol #:nodoc:

      # This module has object checks in it.
      module Checks #:nodoc:

        # Is the symbol a valid value for a Mongoid id?
        #
        # @example Is the string an id value?
        #   :_id.mongoid_id?
        #
        # @return [ true, false ] If the symbol is :id or :_id.
        #
        # @since 2.3.1
        def mongoid_id?
          to_s =~ /^(|_)id$/
        end
      end
    end
  end
end
