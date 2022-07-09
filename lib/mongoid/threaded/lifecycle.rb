# frozen_string_literal: true

module Mongoid
  module Threaded
    BIND = 'bind'.freeze
    ASSIGN = 'assign'.freeze
    BUILD = 'build'.freeze
    LOAD = 'load'.freeze
    CREATE = 'create'.freeze
    
    # This module contains convenience methods for document lifecycle that
    # resides on thread locals.
    module Lifecycle
      extend ActiveSupport::Concern

      private

      # Begin the assignment of attributes. While in this block embedded
      # documents will not autosave themselves in order to allow the document to
      # be in a valid state.
      #
      # @example Execute the assignment.
      #   _assigning do
      #     person.attributes = { :addresses => [ address ] }
      #   end
      #
      # @return [ Object ] The yielded value.
      def _assigning
        Threaded.begin_execution(ASSIGN)
        yield
      ensure
        Threaded.exit_execution(ASSIGN)
      end

      # Is the current thread in assigning mode?
      #
      # @example Is the current thread in assigning mode?
      #   proxy._assigning?
      #
      # @return [ true | false ] If the thread is assigning.
      def _assigning?
        Threaded.executing?(ASSIGN)
      end

      # Execute a block in binding mode.
      #
      # @example Execute in binding mode.
      #   binding do
      #     relation.push(doc)
      #   end
      #
      # @return [ Object ] The return value of the block.
      def _binding
        Threaded.begin_execution(BIND)
        yield
      ensure
        Threaded.exit_execution(BIND)
      end

      # Is the current thread in binding mode?
      #
      # @example Is the current thread in binding mode?
      #   proxy.binding?
      #
      # @return [ true | false ] If the thread is binding.
      def _binding?
        Threaded.executing?(BIND)
      end

      # Execute a block in building mode.
      #
      # @example Execute in building mode.
      #   _building do
      #     relation.push(doc)
      #   end
      #
      # @return [ Object ] The return value of the block.
      def _building
        Threaded.begin_execution(BUILD)
        yield
      ensure
        Threaded.exit_execution(BUILD)
      end

      # Is the current thread in building mode?
      #
      # @example Is the current thread in building mode?
      #   proxy._building?
      #
      # @return [ true | false ] If the thread is building.
      def _building?
        Threaded.executing?(BUILD)
      end

      # Is the current thread in creating mode?
      #
      # @example Is the current thread in creating mode?
      #   proxy.creating?
      #
      # @return [ true | false ] If the thread is creating.
      def _creating?
        Threaded.executing?(CREATE)
      end

      # Execute a block in loading mode.
      #
      # @example Execute in loading mode.
      #   _loading do
      #     relation.push(doc)
      #   end
      #
      # @return [ Object ] The return value of the block.
      def _loading
        Threaded.begin_execution(LOAD)
        yield
      ensure
        Threaded.exit_execution(LOAD)
      end

      # Is the current thread in loading mode?
      #
      # @example Is the current thread in loading mode?
      #   proxy._loading?
      #
      # @return [ true | false ] If the thread is loading.
      def _loading?
        Threaded.executing?(LOAD)
      end

      module ClassMethods

        # Execute a block in creating mode.
        #
        # @example Execute in creating mode.
        #   creating do
        #     relation.push(doc)
        #   end
        #
        # @return [ Object ] The return value of the block.
        def _creating
          Threaded.begin_execution(CREATE)
          yield
        ensure
          Threaded.exit_execution(CREATE)
        end

      end
    end
  end
end
