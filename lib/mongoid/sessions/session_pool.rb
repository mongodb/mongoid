require 'monitor'
require 'thread'
require 'thread_safe'

module Mongoid
  module Sessions
    class SessionPool
      class Queue
        class ConnectionTimeoutError < StandardError; end

        def initialize(lock=Monitor.new)
          @lock = lock
          @cond = @lock.new_cond
          @num_waiting = 0
          @queue = []
        end

        # Checks to see if anyone is waiting for a session
        def any_waiting?
          synchronize do
            @num_waiting > 0
          end
        end

        # Number waiters for a session
        def num_waiting
          synchronize do
            @num_waiting
          end
        end

        # Adds a session to the queue
        def add(session)
          synchronize do
            @queue.push session
            @cond.signal
          end
        end

        # Removes a session from the queue
        def remove
          synchronize do
            @queue.shift
          end
        end

        # Asks the queue for a new session
        def poll(timeout = nil)
          synchronize do
            if timeout
              no_wait_poll || wait_poll(timeout)
            else
              no_wait_poll
            end
          end
        end

        # Get the number of items in the queue
        def count
          @queue.count
        end

        private

        def synchronize(&block)
          @lock.synchronize(&block)
        end

        def any?
          !@queue.empty?
        end

        # Checks to see if there is a session available now
        def can_remove_no_wait?
          @queue.size > @num_waiting
        end

        # Returns a session immediately if there is one available
        def no_wait_poll
          remove if can_remove_no_wait?
        end

        # Poll the queue to for an available session
        # Returns error if tmeout is exceeded
        def wait_poll(timeout)
          @num_waiting += 1

          t0 = Time.now
          elapsed = 0
          loop do
            @cond.wait(timeout - elapsed)

            return remove if any?

            elapsed = Time.now - t0
            if elapsed >= timeout
              msg = 'Timed out waiting for database session'
              raise ConnectionTimeoutError, msg
            end
          end
        ensure
          @num_waiting -= 1
        end
      end

      include MonitorMixin

      attr_reader :sessions, :size, :reaper, :reserved_sessions, :available

      def initialize(opts={})
        super()
        opts[:name] || :default

        @reaper = Reaper.new(opts[:reap_frequency], self)
        @reaper.run

        @checkout_timeout = opts[:checkout_timeout]

        @size = opts[:size]
        @name = opts[:name]
        @sessions = []
        @reserved_sessions = ThreadSafe::Cache.new(:initial_capacity => @size)
        @available = Queue.new self
      end

      # Checkout session from the available pool and put in reserved_sessions
      #
      # @example Checkout a session
      #   sesion_pool.checkout
      #
      # @return [ Moped::Session ] The requested session
      def checkout
        unless (session = session_for_thread(Thread.current))
          synchronize do
            session = get_session
            reserve(session)
          end
        end
        session
      end

      # Checks a session back into the available pool
      #
      # @example Checkin a session
      #   session_pool.checkin
      #
      # @return [ true ] True
      def checkin(session)
        synchronize do
          @available.add session
          release(session)
        end
        true
      end

      # Checks in the session for the given thread
      #
      # @example
      #   session_pool.checking_for_thread(Thread.current)
      #
      # @return [ true] True
      def checkin_from_thread(thread)
        checkin session_for_thread(thread)
        true
      end


      # Clear the sessions for the given thread
      #
      # @example Clear the sessions
      #   session_pool.clear
      #
      # @return [ Hash ] Remaining reserved sessions
      def clear(thread=nil)
        if thread
          @reserved_sessions.delete(thread) if session_for_thread(thread)
          @sessions.pop
        else
          @reserved_sessions = {}
          @sessions = []
          @available = []
        end
      end

      # Checks the number of available sessions
      #
      # @example Get the count
      #   session_pool.count
      #
      # @return [ Integer ] Number of available sessions
      def count
        @available.count
      end

      # Reaps sessions from dead/sleeping threads
      # Sessions get returned to the available pool
      #
      # @example Reap sessions
      #   session_pool.reap
      #
      # @return [ true ] True
      def reap
        @reserved_sessions.keys.each do |thread|
          session = @reserved_sessions[thread]
          checkin(session) if thread.stop?
        end
        true
      end

      # Gets the session for the given thread
      #
      # @example Get the session for a thread
      #   session_pool.session_for_thread(Thread.current)
      #
      # @return [ Moped::Session ] Session for the given thread
      def session_for_thread(thread)
        @reserved_sessions[thread]
      end

      private

      # Sets the session as reserved
      #
      # @api private
      #
      # @example Reserve a session
      #   session_pool.reserve(session)
      #
      # @return [ Moped::Session ] The reserved session
      def reserve(session)
        @reserved_sessions[current_session_id] = session
      end

      def current_session_id
        Thread.current  # Do not store as object_id because
                        # Rubinius ObjecSpace._id2ref is extremely slow
                        # This ends up as the hash key for reserved_sessions
                        # We need access to the thread so sessions can be reaped
                        # after the thread is dead
      end

      # Release session from reservation
      #
      # @api private
      #
      # @example Release the session
      #   session_pool.release(session)
      #
      # @return [ Moped::Session ] The released session
      def release(session)
        thread = if @reserved_sessions[current_session_id] == session
                   current_session_id
                 else
                   @reserved_sessions.keys.find do |k|
                     @reserved_sessions[k] == session
                   end
                 end
        @reserved_sessions.delete thread if thread
      end

      # Asks for an available queue for a session
      #
      # @api private
      #
      # @example Request a session
      #   session_pool.get_session
      #
      # @rturn [ Moped::Session ] The reserved session
      def get_session
        if session = @available.poll
          session
        elsif @sessions.size < @size
          checkout_new_session
        else
          @available.poll(@checkout_timeout)
        end
      end

      # Creates a new session and checks it out from the available pool
      #
      # @api private
      #
      # @example checkout a  new session
      #   session_pool.checkout_new_session
      #
      # @return [ Moped::Session ] The new session
      def checkout_new_session
        session = new_session
        @sessions << session
        session
      end

      # Creates a new session
      #
      # @api private
      #
      # @example Create a new session
      #   sesion_pool.new_session
      #
      # @return [ Moped::Session ] The created session
      def new_session
        Factory.create(@name)
      end

      class Reaper
        attr_reader :pool
        attr_reader :frequency
        def initialize(frequency, pool)
          @frequency = frequency
          @pool = pool
        end

        def run
          return unless frequency
          Thread.new(frequency, pool) do |t, p|
            while true
              sleep t
              p.reap
            end
          end
        end
      end

    end
  end
end

