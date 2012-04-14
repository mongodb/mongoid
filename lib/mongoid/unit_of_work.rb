# encoding: utf-8
module Mongoid

  # This module handles unit of work functionality with regards to the identity
  # map.
  module UnitOfWork

    # We can process a unit of work in Mongoid and have the identity map
    # automatically clear itself out after the work is complete.
    #
    # @example Process a unit of work.
    #   Mongoid.unit_of_work do
    #     Person.create(title: "Sir")
    #   end
    #
    # @example Process with identity map disabled on the current thread.
    #   Mongoid.unit_of_work(disable: :current) do
    #     Person.create(title: "Sir")
    #   end
    #
    # @example Process with identity map disabled on all threads.
    #   Mongoid.unit_of_work(disable: :all) do
    #     Person.create(title: "Sir")
    #   end
    #
    # @param [ Hash ] options The disabling options.
    #
    # @option [ Symbol ] :disable Either :all or :current to indicate whether
    #   to temporarily disable the identity map on the current thread or all
    #   threads.
    #
    # @return [ Object ] The result of the block.
    #
    # @since 2.1.0
    def unit_of_work(options = {})
      disable = options[:disable]
      begin
        Threaded.disable_identity_map(disable) if disable
        yield if block_given?
      ensure
        if disable
          Threaded.enable_identity_map(disable)
        else
          IdentityMap.clear
        end
      end
    end

    # Are we currently using the identity map?
    #
    # @example Is the identity map currently enabled?
    #   Mongoid.using_identity_map?
    #
    # @return [ true, false ] If the identity map is in use.
    #
    # @since 3.0.0
    def using_identity_map?
      Mongoid.identity_map_enabled? && Threaded.identity_map_enabled?
    end
  end
end
