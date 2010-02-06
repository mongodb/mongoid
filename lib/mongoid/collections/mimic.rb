# encoding: utf-8
module Mongoid #:nodoc:
  module Collections #:nodoc:
    module Mimic #:nodoc:
      # Proxy all the supplied operations to the internal collection or target.
      #
      # Example:
      #
      # <tt>proxy Operations::ALL, :collection</tt>
      def proxy(target, operations)
        operations.each do |name|
          define_method(name) { |*args| send(target).send(name, *args) }
        end
      end
    end
  end
end
