require 'active_support/core_ext/module/attr_internal'
require 'mongoid/log_subscriber'

module Mongoid
  module Railties # :nodoc:
    module ControllerRuntime #:nodoc:
      extend ActiveSupport::Concern

    protected

      attr_internal :mongoid_runtime

      def process_action(action, *args)
        # We also need to reset the runtime before each action
        # because of queries in middleware or in cases we are streaming
        # and it won't be cleaned up by the method below.
        Mongoid::LogSubscriber.reset_runtime
        super
      end

      def cleanup_view_runtime
        db_rt_before_render = Mongoid::LogSubscriber.reset_runtime
        self.mongoid_runtime = (mongoid_runtime || 0) + db_rt_before_render
        runtime = super
        db_rt_after_render = Mongoid::LogSubscriber.reset_runtime
        self.mongoid_runtime += db_rt_after_render
        runtime - db_rt_after_render
      end

      def append_info_to_payload(payload)
        super
        payload[:mongoid_runtime] = (mongoid_runtime || 0) + Mongoid::LogSubscriber.reset_runtime
      end

      module ClassMethods # :nodoc:
        def log_process_action(payload)
          messages, mongoid_runtime = super, payload[:mongoid_runtime]
          messages << ("Mongoid: %.1fms" % mongoid_runtime.to_f) if mongoid_runtime
          messages
        end
      end
    end
  end
end