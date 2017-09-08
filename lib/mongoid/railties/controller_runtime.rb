module Mongoid
  module Railties
    module ControllerRuntime

      module ControllerExtension
        extend ActiveSupport::Concern

        protected

        attr_internal :mongo_runtime

        def cleanup_view_runtime
          mongo_rt_before_render = Instrument.reset_runtime
          runtime = super
          mongo_rt_after_render = Instrument.reset_runtime
          self.mongo_runtime = mongo_rt_before_render + mongo_rt_after_render
          runtime - mongo_rt_after_render
        end

        def append_info_to_payload payload
          super
          payload[:mongo_runtime] = (mongo_runtime || 0) + Instrument.reset_runtime
        end

        module ClassMethods

          def log_process_action payload
            messages, mongo_runtime = super, payload[:mongo_runtime]
            messages << ("MongoDB: %.1fms" % mongo_runtime.to_f) if mongo_runtime
            messages
          end

        end

      end

      class Instrument

        VARIABLE_NAME = 'Mongoid.controller_runtime'.freeze

        def started _; end

        def completed e
          Instrument.runtime += e.duration
        end
        alias :succeeded :completed
        alias :failed :completed

        def self.runtime
          Thread.current[VARIABLE_NAME] ||= 0
        end

        def self.runtime= value
          Thread.current[VARIABLE_NAME] = value
        end

        def self.reset_runtime
          _runtime = runtime
          self.runtime = 0
          _runtime
        end

      end

    end
  end
end