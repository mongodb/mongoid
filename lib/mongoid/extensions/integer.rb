# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions #:nodoc:
    module Integer

      # Is the object not to be converted to bson on criteria creation?
      #
      # @example Is the object unconvertable?
      #   object.unconvertable_to_bson?
      #
      # @return [ true ] If the object is unconvertable.
      #
      # @since 2.2.1
      def unconvertable_to_bson?
        true
      end
    end
  end
end

::Integer.__send__(:include, Mongoid::Extensions::Integer)
