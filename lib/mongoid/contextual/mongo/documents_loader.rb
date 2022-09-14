require "mongoid/association/eager_loadable"

module Mongoid
  module Contextual
    class Mongo
      # Loads documents for the provided criteria.
      #
      # @api private
      class DocumentsLoader
        extend Forwardable
        include Association::EagerLoadable

        def_delegators :@future, :value!, :value, :wait!, :wait

        # Synchronous executor to be used when async_query_executor config option
        # is set to :immediate. This excutor runs all operations on the current
        # thread, blocking as necessary.
        IMMEDIATE_EXECUTOR = Concurrent::ImmediateExecutor.new

        # Returns suitable executor according to Mongoid config options.
        #
        # @return [ Concurrent::ImmediateExecutor | Concurrent::ThreadPoolExecutor ] The executor
        #   to be used to execute document loading tasks.
        def self.executor
          case Mongoid.async_query_executor
          when :immediate
            IMMEDIATE_EXECUTOR
          when :global_thread_pool
            Mongoid.global_thread_pool_async_query_executor
          end
        end

        # @return [ Mongoid::Criteria ] Criteria that specifies which documents should
        #   be loaded. Exposed here because `eager_loadable?` method from
        #   `Association::EagerLoadable` expects is to be available.
        attr_accessor :criteria

        # Instantiates the document loader instance and immediately schedules
        # its execution using the provided executor.
        #
        # @param [ Mongo::Collection::View ] view The collection view to get
        #   records from the database.
        # @param [ Class ] klass Mongoid model class to instantiate documents.
        #   All records obtained from the database will be converted to an
        #   instance of this class, if possible.
        # @param [ Mongoid::Criteria ] criteria. Criteria that specifies which
        #   documents should be loaded.
        # @param [ Concurrent::AbstractExecutorService ] executor. Executor that
        #   is capable of running `Concurrent::Promises::Future` instances.
        def initialize(view, klass, criteria, executor: self.class.executor)
          @view = view
          @klass = klass
          @criteria = criteria
          @mutex = Mutex.new
          @state = :pending
          @future = Concurrent::Promises.future_on(executor, self) do |task|
            if task.pending?
              task.send(:start)
              task.execute
            end
          end
        end

        # Returns false or true whether the loader is in pending state.
        #
        # Pending state means that the loader execution has been scheduled,
        # but has not been started yet.
        #
        # @return [ true | false ] true if the loader is in pending state,
        #   otherwise false.
        def pending?
          @mutex.synchronize do
            @state == :pending
          end
        end

        # Returns false or true whether the loader is in started state.
        #
        # Started state means that the loader execution has been started.
        # Note that the loader stays in this state even after the execution
        # completed (successfully or failed).
        #
        # @return [ true | false ] true if the loader is in started state,
        #   otherwise false.
        def started?
          @mutex.synchronize do
            @state == :started
          end
        end

        # Mark the loader as unscheduled.
        #
        # If the loader is marked unscheduled, it will not be executed. The only
        # option to load the documents is to call `execute` method directly.
        #
        # Please note that if execution of a task has been already started,
        # unscheduling does not have any effect.
        def unschedule
          @mutex.synchronize do
            @state = :cancelled unless @state == :started
          end
        end

        # Loads records specified by `@criteria` from the database, and convert
        # them to Mongoid documents of `@klass` type.
        #
        # This method is called by the task (possibly asynchronous) scheduled
        # when creating an instance of the loader. However, this method can be
        # called directly, if it is desired to execute loading on the caller
        # thread immediately.
        #
        # Calling this method does not change the state of the loader.
        #
        # @return [ Array<Mongoid::Document> ] Array of document loaded from
        #   the database.
        def execute
          documents = @view.map do |doc|
            Factory.from_db(@klass, doc, @criteria)
          end
          eager_load(documents) if eager_loadable?
          documents
        end

        private

        # Mark the loader as started.
        def start
          @mutex.synchronize do
            @state = :started
          end
        end
      end
    end
  end
end
