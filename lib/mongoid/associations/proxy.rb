# encoding: utf-8
module Mongoid #:nodoc
  module Associations #:nodoc
    class Proxy #:nodoc
      instance_methods.each do |method|
        undef_method(method) unless method =~ /(^__|^nil\?$|^send$|^object_id$|^extend$)/
      end
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

      # Sets up the parent, klass, foreign_key, options
      def setup(document, options)
        @parent = document
        @klass = options.klass
        @options = options
        @foreign_key = options.foreign_key
        extends(options)
      end
    end
  end
end
