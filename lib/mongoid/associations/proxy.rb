# encoding: utf-8
module Mongoid #:nodoc
  module Associations #:nodoc
    module Proxy #:nodoc
      def self.included(base)
        base.class_eval do
          instance_methods.each do |method|
            undef_method(method) unless method =~ /(^__|^nil\?$|^send$|^object_id$|^extend$)/
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

        # If anonymous extensions are added this will take care of them.
        def extends(options)
          extend Module.new(&options.extension) if options.extension?
        end
      end
    end
  end
end
