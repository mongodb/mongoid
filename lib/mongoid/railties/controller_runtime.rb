module Mongoid
  module Railties
    module ControllerRuntime

      # This extension mimics the Rails' internal method to
      # measure ActiveRecord runtime during request processing.
      # It appends MongoDB runtime value (`mongoid_runtime`) into payload
      # of instrumentation event `process_action.action_controller`.
      module ControllerExtension
        extend ActiveSupport::Concern

        protected

        attr_internal :mongoid_runtime

        # reset the runtime before each action
        def process_action *_
          Collector.reset_runtime
          super
        end

        # override to collect the measurements
        def cleanup_view_runtime
          mongo_rt_before_render = Collector.reset_runtime
          runtime = super
          mongo_rt_after_render = Collector.reset_runtime
          self.mongoid_runtime = mongo_rt_before_render + mongo_rt_after_render
          runtime - mongo_rt_after_render
        end

        # add the measurement to a instrumentation event payload
        def append_info_to_payload payload
          super
          payload[:mongoid_runtime] = (mongoid_runtime || 0) + Collector.reset_runtime
        end

        module ClassMethods

          # append MongoDB runtime information to action log message
          def log_process_action payload
            messages = super
            mongoid_runtime = payload[:mongoid_runtime]
            messages << ("MongoDB: %.1fms" % mongoid_runtime.to_f) if mongoid_runtime
            messages
          end

        end

      end

      # The Collector of MongoDB runtime metric, that subscribes to Mongo internal monitoring.
      # Stores the value within Thread variable to leverage multithreaded servers.
      class Collector

        VARIABLE_NAME = "Mongoid.controller_runtime".freeze

        def started _; end

        def _completed e
          Collector.runtime += e.duration
        end
        alias :succeeded :_completed
        alias :failed :_completed

        def self.runtime
          Thread.current[VARIABLE_NAME] ||= 0
        end

        def self.runtime= value
          Thread.current[VARIABLE_NAME] = value
        end

        def self.reset_runtime
          to_now = runtime
          self.runtime = 0
          to_now
        end

      end

    end
  end
end