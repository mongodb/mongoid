require "mongoid/association/eager_loadable"

module Mongoid
  module Contextual
    class Mongo
      # @api private
      class PreloadTask
        extend Forwardable
        include Association::EagerLoadable

        def_delegators :@future, :value!, :value, :wait!, :wait

        IMMEDIATE_EXECUTOR = Concurrent::ImmediateExecutor.new

        attr_accessor :criteria

        def initialize(view, klass, criteria)
          @view = view
          @klass = klass
          @criteria = criteria
          @mutex = Mutex.new
          @state = :pending
          @future = Concurrent::Promises.future_on(executor, self) do |task|
            if task.pending?
              task.execute
            end
          end
        end

        def executor
          case Mongoid.async_query_executor
          when :immediate
            IMMEDIATE_EXECUTOR
          when :global_thread_pool
            Mongoid.global_thread_pool_async_query_executor
          end
        end

        def pending?
          @mutex.synchronize do
            @state == :pending
          end
        end

        def started?
          @mutex.synchronize do
            @state == :started
          end
        end

        def unschedule
          @mutex.synchronize do
            @state = :cancelled
          end
        end

        def execute
          start
          documents = @view.map do |doc|
            Factory.from_db(@klass, doc, @criteria)
          end
          eager_load(documents) if eager_loadable?
          documents
        end

        private

        def start
          @mutex.synchronize do
            @state = :started
          end
        end
      end
    end
  end
end
