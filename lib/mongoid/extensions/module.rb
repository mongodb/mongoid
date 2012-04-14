# encoding: utf-8
module Mongoid
  module Extensions
    module Module

      # Redefine the method. Will undef the method if it exists or simply
      # just define it.
      #
      # @example Redefine the method.
      #   Object.re_define_method("exists?") do
      #     self
      #   end
      #
      # @param [ String, Symbol ] name The name of the method.
      # @param [ Proc ] block The method body.
      #
      # @return [ Method ] The new method.
      #
      # @since 3.0.0
      def re_define_method(name, &block)
        undef_method(name) if method_defined?(name)
        define_method(name, &block)
      end
    end
  end
end

::Module.__send__(:include, Mongoid::Extensions::Module)
