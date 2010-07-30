# encoding: utf-8
module Mongoid #:nodoc
  module Associations #:nodoc
    class Proxy #:nodoc
      instance_methods.each do |method|
        undef_method(method) unless method =~ /(^__|^send$|^object_id$|^extend$)/
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

      protected
      class << self
        def check_dependent_not_allowed!(options)
          if options.has_key?(:dependent)
            raise Errors::InvalidOptions.new(
              "dependent_only_references_one_or_many", {}
            )
          end
        end

        def check_inverse_not_allowed!(options)
          if options.has_key?(:inverse_of)
            raise Errors::InvalidOptions.new(
              "association_cant_have_inverse_of", {}
            )
          end
        end

        def check_inverse_must_be_defined!(options)
          unless options.has_key?(:inverse_of)
            raise Errors::InvalidOptions.new(
              "embedded_in_must_have_inverse_of", {}
            )
          end
        end
      end
    end
  end
end
