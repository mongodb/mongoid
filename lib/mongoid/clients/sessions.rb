# frozen_string_literal: true

module Mongoid
  module Clients

    # Encapsulates behavior for using sessions and transactions.
    module Sessions

      # Execute a block within the context of a session.
      #
      # @example Execute some operations in the context of a session.
      #   band.with_session(causal_consistency: true) do
      #     band.records << Record.create
      #     band.name = 'FKA Twigs'
      #     band.save
      #     band.reload
      #   end
      #
      # @param [ Hash ] options The session options. Please see the driver
      #   documentation for the available session options.
      #
      # @raise [ Errors::InvalidSessionUse ] If an operation is attempted on a model using another
      #   client from which the session was started or if sessions are nested.
      #
      # @return [ Object ] The result of calling the block.
      #
      # @yieldparam [ Mongo::Session ] The session being used for the block.
      def with_session(options = {})
        if Threaded.get_session(client: persistence_context.client)
          raise Mongoid::Errors::InvalidSessionNesting.new
        end
        session = persistence_context.client.start_session(options)
        Threaded.set_session(session, client: persistence_context.client)
        yield(session)
      rescue Mongo::Error::InvalidSession => ex
        if Mongo::Error::SessionsNotSupported === ex
          raise Mongoid::Errors::SessionsNotSupported.new
        else
          raise ex
        end
      ensure
        Threaded.clear_session(client: persistence_context.client)
      end

      # Executes a block within the context of a transaction.
      #
      # @param [ Hash ] options The transaction options. Please see the driver
      #   documentation for the available session options.
      # @param [ Hash ] session_options The session options. A MongoDB
      #   transaction must be started inside a session, therefore a session will
      #   be started. Please see the driver documentation for the available session options.
      #
      # @yield Provided block will be executed inside a transaction.
      def transaction(options = {}, session_options: {})
        with_session(session_options) do |session|
          begin
            session.start_transaction(options)
            yield
            session.commit_transaction
          rescue Mongoid::Errors::Rollback
            session.abort_transaction
          rescue Mongoid::Errors::InvalidSessionNesting
            session.abort_transaction unless session.ended?
            raise Mongoid::Errors::InvalidTransactionNesting.new
          rescue Mongoid::Errors::SessionsNotSupported
            session.abort_transaction unless session.ended?
            raise Mongoid::Errors::TransactionsNotSupported.new
          rescue Mongo::Error::InvalidSession, Mongo::Error::InvalidTransactionOperation => e
            session.abort_transaction unless session.ended?
            raise Mongoid::Errors::TransactionError(e)
          rescue StandardError => e
            session.abort_transaction unless session.ended?
            raise e
          end
        end
      end

      private

      def _session
        Threaded.get_session(client: persistence_context.client)
      end

      module ClassMethods

        # Execute a block within the context of a session.
        #
        # @example Execute some operations in the context of a session.
        #   Band.with_session(causal_consistency: true) do
        #     band = Band.create
        #     band.records << Record.new
        #     band.save
        #     band.reload.records
        #   end
        #
        # @param [ Hash ] options The session options. Please see the driver
        #   documentation for the available session options.
        #
        # @raise [ Errors::InvalidSessionUse ] If an operation is attempted on a model using another
        #   client from which the session was started or if sessions are nested.
        #
        # @return [ Object ] The result of calling the block.
        #
        # @yieldparam [ Mongo::Session ] The session being used for the block.
        def with_session(options = {})
          if Threaded.get_session(client: persistence_context.client)
            raise Mongoid::Errors::InvalidSessionNesting.new
          end
          session = persistence_context.client.start_session(options)
          Threaded.set_session(session, client: persistence_context.client)
          yield(session)
        rescue Mongo::Error::InvalidSession => ex
          if Mongo::Error::SessionsNotSupported === ex
            raise Mongoid::Errors::SessionsNotSupported.new
          else
            raise ex
          end
        ensure
          Threaded.clear_session(client: persistence_context.client)
        end

        def transaction(options = {}, session_options: {})
          with_session(session_options) do |session|
            begin
              session.start_transaction(options)
              yield
              session.commit_transaction
            rescue Mongoid::Errors::Rollback
              session.abort_transaction unless session.ended?
            rescue Mongoid::Errors::InvalidSessionNesting
              session.abort_transaction unless session.ended?
              raise Mongoid::Errors::InvalidTransactionNesting.new
            rescue Mongoid::Errors::SessionsNotSupported
              session.abort_transaction unless session.ended?
              raise Mongoid::Errors::TransactionsNotSupported.new
            rescue Mongo::Error::InvalidSession, Mongo::Error::InvalidTransactionOperation => e
              session.abort_transaction unless session.ended?
              raise Mongoid::Errors::TransactionError(e)
            rescue StandardError => e
              session.abort_transaction unless session.ended?
              raise e
            end
          end
        end

        private

        def _session
          Threaded.get_session(client: persistence_context.client)
        end
      end
    end
  end
end
