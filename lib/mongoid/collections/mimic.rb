# encoding: utf-8
module Mongoid #:nodoc:
  module Collections #:nodoc:
    module Mimic #:nodoc:
      # Proxy all the supplied operations to the internal collection.
      def proxy(operations)
        operations.each do |name|
          define_method(name) { |*args| collection.send(name, *args) }
        end
      end
    end
  end
end
