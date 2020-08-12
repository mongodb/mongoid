# frozen_string_literal: true
# encoding: utf-8

module Mongoid

  # Extends Mongo::Client with session management behavior.
  #
  # @since 7.1.2
  class Client < Mongo::Client

    # Execute a block within the context of a session.
    #
    # @example Execute some operations in the context of a session.
    #   client.with_session(causal_consistency: true) do
    #     band = Band.create
    #     band.records << Record.new
    #     band.save
    #     band.reload.records
    #   end
    #
    # @param [ Hash ] options The session options. Please see the driver
    #   documentation for the available session options.
    #
    # @note You cannot do any operations in the block using models or objects
    #   that use a different client; the block will execute all operations
    #   in the context of the implicit session and operations on any models using
    #   another client will fail. For example, if you set a client using store_in on a
    #   particular model and execute an operation on it in the session context block,
    #   that operation can't use the block's session and an error will be raised.
    #   An error will also be raised if sessions are nested.
    #
    # @raise [ Errors::InvalidSessionUse ] If an operation is attempted on a model using another
    #   client from which the session was started or if sessions are nested.
    #
    # @return [ Object ] The result of calling the block.
    #
    # @yieldparam [ Mongo::Session ] The session being used for the block.
    #
    # @since 7.1.2
    def with_session(options = {})
      if Threaded.get_session
        raise Mongoid::Errors::InvalidSessionUse.new(:invalid_session_nesting)
      end
      session = start_session(options)
      Threaded.set_session(session)
      yield(session)
    rescue Mongo::Error::InvalidSession => ex
      if
        # Driver 2.13.0+
        defined?(Mongo::Error::SessionsNotSupported) &&
          Mongo::Error::SessionsNotSupported === ex ||
        # Legacy drivers
        ex.message == Mongo::Session::SESSIONS_NOT_SUPPORTED
      then
        raise Mongoid::Errors::InvalidSessionUse.new(:sessions_not_supported)
      end
      raise Mongoid::Errors::InvalidSessionUse.new(:invalid_session_use)
    ensure
      Threaded.clear_session
    end

    private

    def _session
      Threaded.get_session
    end
  end
end
