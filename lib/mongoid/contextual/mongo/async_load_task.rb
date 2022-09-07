require "mongoid/association/eager_loadable"

module Mongoid
  module Contextual
    class Mongo
      class AsyncLoadTask
        include Association::EagerLoadable

        IMMEDIATE_EXECUTOR = Concurrent::ImmediateExecutor.new

        attr_accessor :future, :criteria

        def initialize(view, klass, criteria)
          @view = view
          @klass = klass
          @criteria = criteria

          @mutex = Mutex.new
          @started = false
          @cancelled = false
          @future = Concurrent::Promises.future_on(executor, self) do |task|
            if !task.started? && !task.cancelled?
              task.execute
            end
          end.touch
        end

        def executor
          case Mongoid.async_query_executor
          when :immediate
            IMMEDIATE_EXECUTOR
          when :global_thread_pool
            Mongoid.global_thread_pool_async_query_executor
          end
        end

        def started?
          @mutex.synchronize do
            @started
          end
        end

        def cancel
          @mutex.synchronize do
            @cancelled = true
          end
        end

        def cancelled?
          @mutex.synchronize do
            @cancelled
          end
        end

        def execute
          started!
          documents = @view.map do |doc|
            Factory.from_db(@klass, doc, @criteria)
          end
          eager_load(documents) if eager_loadable?
          documents
        end

        private

        def started!
          @mutex.synchronize do
            @started = true
          end
        end
      end
    end
  end
end
