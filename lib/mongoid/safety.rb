# encoding: utf-8
module Mongoid #:nodoc:

  # The +Safety+ module is used to provide a DSL to execute database operations
  # in safe mode on a per query basis, either from the +Document+ class level
  # or instance level.
  module Safety
    extend ActiveSupport::Concern

    # Execute the following instance-level persistence operation in safe mode.
    #
    # @example Upsert in safe mode.
    #   person.safely.upsert
    #
    # @example Destroy in safe mode with w and fsync options.
    #   person.safely(:w => 2, :fsync => true).destroy
    #
    # @param [ Hash ] options The safe mode options.
    #
    # @option options [ Integer ] :w The number of nodes to write to.
    # @option options [ Integer ] :wtimeout Time to wait for return from all
    #   nodes.
    # @option options [ true, false ] :fsync Should a fsync occur.
    #
    # @return [ Proxy ] The safety proxy.
    def safely(safety = true)
      tap { Threaded.safety_options = safety }
    end

    # Execute the following instance-level persistence operation without safe mode.
    # Allows per-request overriding of safe mode when the persist_in_safe_mode
    # config option is turned on.
    #
    # @example Upsert in safe mode.
    #   person.unsafely.upsert
    #
    # @return [ Proxy ] The safety proxy.
    def unsafely
      tap { Threaded.safety_options = false }
    end

    class << self

      # Clear the safety options off the current thread.
      #
      # @example Clear the safety options.
      #   Safety.clear
      #
      # @return [ true ] True.
      #
      # @since 3.0.0
      def clear
        Threaded.clear_safety_options!
        true
      end

      # Get the safe mode persistence options, either from the current thread
      # or the configuration.
      #
      # @example Get the current safe mode options.
      #   Safety.options
      #
      # @return [ true, false, Hash ] The safe mode options.
      #
      # @since 3.0.0
      def options
        if Threaded.safety_options.nil?
          Mongoid.persist_in_safe_mode
        else
          Threaded.safety_options
        end
      end
    end

    module ClassMethods #:nodoc:

      # Execute the following class-level persistence operation in safe mode.
      #
      # @example Create in safe mode.
      #   Person.safely.create(:name => "John")
      #
      # @example Delete all in safe mode with options.
      #   Person.safely(:w => 2, :fsync => true).delete_all
      #
      # @param [ Hash ] options The safe mode options.
      #
      # @option options [ Integer ] :w The number of nodes to write to.
      # @option options [ Integer ] :wtimeout Time to wait for return from all
      #   nodes.
      # @option options [ true, false ] :fsync Should a fsync occur.
      #
      # @return [ Proxy ] The safety proxy.
      def safely(safety = true)
        tap { Threaded.safety_options = safety }
      end

      # Execute the following class-level persistence operation without safe mode.
      # Allows per-request overriding of safe mode when the persist_in_safe_mode
      # config option is turned on.
      #
      # @example Upsert in safe mode.
      #   Person.unsafely.create(:name => "John")
      #
      # @return [ Proxy ] The safety proxy.
      #
      # @since 2.3.0
      def unsafely
        tap { Threaded.safety_options = false }
      end
    end
  end
end
