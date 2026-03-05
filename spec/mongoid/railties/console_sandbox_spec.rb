# rubocop:todo all
require 'spec_helper'
require 'mongoid/railties/console_sandbox'

describe 'console_sandbox' do
  describe '#check_if_transactions_might_be_available!' do
    context 'cluster may support transactions' do
      require_topology :replica_set, :sharded, :load_balanced

      it 'does not raise' do
        expect do
          check_if_transactions_might_be_available!(Mongoid.default_client)
        end.not_to raise_error
      end
    end

    context 'cluster does not support transactions' do
      require_topology :single

      it 'raises an error' do
        expect do
          check_if_transactions_might_be_available!(Mongoid.default_client)
        end.to raise_error(Mongoid::Errors::TransactionsNotSupported)
      end
    end
  end

  describe '#start_sandbox_transaction' do
    require_transaction_support

    before do
      start_sandbox_transaction(Mongoid.default_client)
    end

    after do
      Mongoid.send(:_session).abort_transaction
      Mongoid::Threaded.clear_session(client: Mongoid.default_client)
    end

    it 'starts transaction' do
      expect(Mongoid.send(:_session)).to be_in_transaction
    end
  end
end
