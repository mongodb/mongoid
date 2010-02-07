# encoding: utf-8
module Mongoid #:nodoc:
  module Collections #:nodoc:
    module Mimic #:nodoc:
      def self.included(base)
        base.class_eval do
          include InstanceMethods
          extend ClassMethods
        end
      end

      module InstanceMethods #:nodoc:
        # Retry the supplied operation until the reconnect time has expired,
        # defined in the mongoid Config module.
        #
        # Example:
        #
        # <tt>master.attempt(operation)</tt>
        def attempt(operation, start)
          begin
            elapsed = (Time.now - start)
            operation.call
          rescue Mongo::ConnectionFailure => error
            (elapsed < Mongoid.reconnect_time) ? retry : (raise error)
          end
        end
      end

      module ClassMethods #:nodoc:
        # Proxy all the supplied operations to the internal collection or target.
        #
        # Example:
        #
        # <tt>proxy Operations::ALL, :collection</tt>
        def proxy(target, operations)
          operations.each do |name|
            define_method(name) do |*args|
              operation = lambda { send(target).send(name, *args) }
              attempt(operation, Time.now)
            end
          end
        end
      end
    end
  end
end
