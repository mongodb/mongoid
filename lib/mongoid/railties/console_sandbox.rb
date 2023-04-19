# rubocop:todo all
require "mongoid/threaded"
require "mongoid/errors/transactions_not_supported"

# This method raises an error if the cluster the client is connected to
# does not support transactions in any case. At the moment this is the case
# of the standalone topology.
#
# Please note that if this method did not raise, it does not guarantee that
# transactions are available for the cluster.
#
# @param [ Mongo::Client ] client Client connected to a cluster to be tested.
#
# @raise [ Mongoid::Errors::TransactionsNotSupported ] If the cluster
#   definitely does not support transactions.
def check_if_transactions_might_be_available!(client)
  if client.cluster.single?
    raise Mongoid::Errors::TransactionsNotSupported
  end
end

# Starts a transaction that should include all the operations inside
# the sandboxed console session. This transaction should not be ever committed.
# When a user end the console session, the client will disconnect, and
# the transaction will be automatically aborted therefore.
#
# @param [ Mongo::Client ] client Client to start the transaction.
def start_sandbox_transaction(client)
  session = client.start_session
  ::Mongoid::Threaded.set_session(session, client: client)
  session.start_transaction
end

# Prepares console sandbox mode. This method should be called when
# a user starts rails console with '--sandbox' flag.
def start_sandbox
  Mongoid.persistence_context.client.tap do |client|
    check_if_transactions_might_be_available!(client)
    start_sandbox_transaction(client)
  end
end

