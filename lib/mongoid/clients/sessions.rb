# frozen_string_literal: true

module Mongoid
  module Clients

    # Encapsulates behavior for using sessions and transactions.
    module Sessions

      # Add class method mixin functionality.
      #
      # @todo Replace with ActiveSupport::Concern
      def self.included(base)
        base.include(ClassMethods)
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
        rescue Mongo::Error::OperationFailure => ex
          if (ex.code == 40415 && ex.server_message =~ /startTransaction/) ||
             (ex.code == 20 && ex.server_message =~ /Transaction/)
            raise Mongoid::Errors::TransactionsNotSupported.new
          else
            raise ex
          end
        ensure
          Threaded.clear_session(client: persistence_context.client)
        end

        # Executes a block within the context of a transaction.
        #
        # If the block does not raise an error, the transaction is committed.
        # If an error is raised, the transaction is aborted. The error is passed on
        # except for the `Mongoid::Errors::Rollback`. This error is not passed on,
        # so you can raise is if you want to deliberately rollback the transaction.
        #
        # @param [ Hash ] options The transaction options. Please see the driver
        #   documentation for the available session options.
        # @param [ Hash ] session_options The session options. A MongoDB
        #   transaction must be started inside a session, therefore a session will
        #   be started. Please see the driver documentation for the available session options.
        #
        # @raise [ Mongoid::Errors::InvalidTransactionNesting ] If the transaction is
        #   opened on a client that already has an open transaction.
        # @raise [ Mongoid::Errors::TransactionsNotSupported ] If MongoDB deployment
        #   the client is connected to does not support transactions.
        # @raise [ Mongoid::Errors::TransactionError ] If there is an error raised
        #   by MongoDB deployment or MongoDB driver.
        #
        # @yield Provided block will be executed inside a transaction.
        def transaction(options = {}, session_options: {})
          with_session(session_options) do |session|
            begin
              session.start_transaction(options)
              yield
              commit_transaction(session)
            rescue Mongoid::Errors::Rollback
              abort_transaction(session)
            rescue Mongoid::Errors::InvalidSessionNesting
              # Session should be ended here.
              raise Mongoid::Errors::InvalidTransactionNesting.new
            rescue Mongo::Error::InvalidSession, Mongo::Error::InvalidTransactionOperation => e
              abort_transaction(session)
              raise Mongoid::Errors::TransactionError(e)
            rescue StandardError => e
              abort_transaction(session)
              raise e
            end
          end
        end

        private

        # @return [ Mongo::Session ] Session for the current client.
        def _session
          Threaded.get_session(client: persistence_context.client)
        end

        # This method should be used to detect whether a persistence operation
        # is executed inside transaction or not.
        #
        # Currently this method is used to detect when +after_commit+ callbacks
        # should be triggered. If we introduce implicit transactions and
        # therefore do not need to handle two different ways of triggering callbacks,
        # we may want to remove this method.
        #
        # @return [ true | false ] Whether there is a session for the current
        #   client, and there is a transaction in progress for this session.
        def in_transaction?
          _session&.in_transaction? || false
        end

        # Commits the active transaction on the session, and calls
        # after_commit callbacks on modified documents.
        #
        # @param [ Mongo::Session ] session Session on which
        #   a transaction is started.
        def commit_transaction(session)
          session.commit_transaction
          Threaded.clear_modified_documents(session).each do |doc|
            doc.run_after_callbacks(:commit)
          end
        end

        # Aborts the active transaction on the session, and calls
        # after_rollback callbacks on modified documents.
        #
        # @param [ Mongo::Session ] session Session on which
        #   a transaction is started.
        def abort_transaction(session)
          session.abort_transaction
          Threaded.clear_modified_documents(session).each do |doc|
            doc.run_after_callbacks(:rollback)
          end
        end
      end
    end
  end
end
