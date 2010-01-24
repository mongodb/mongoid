# encoding: utf-8
module Mongoid #:nodoc
  module Associations #:nodoc
    module Proxy #:nodoc
      def self.included(base)
        base.class_eval do
          instance_methods.each do |method|
            undef_method(method) unless method =~ /(^__|^nil\?$|^send$|^object_id$)/
          end
          include InstanceMethods
        end
      end
      module InstanceMethods #:nodoc:
        attr_reader \
          :options,
          :target

        # Default behavior of method missing should be to delegate all calls
        # to the target of the proxy. This can be overridden in special cases.
        def method_missing(name, *args, &block)
          @target.send(name, *args, &block)
        end
      end
    end
  end
end
