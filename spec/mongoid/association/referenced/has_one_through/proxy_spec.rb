# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Association::Referenced::HasOneThrough::Proxy do
  before(:all) do
    Object.const_set(:PxHotStore, Class.new { include Mongoid::Document })
    Object.const_set(:PxHotFranchise, Class.new do
      include Mongoid::Document

      has_one :px_hot_store, class_name: 'PxHotStore', inverse_of: :px_hot_franchise
    end)
    Object.const_set(:PxHotCustomer, Class.new do
      include Mongoid::Document

      has_one :px_hot_franchise, class_name: 'PxHotFranchise',
                                 inverse_of: :px_hot_customer
      has_one :px_hot_store, through: :px_hot_franchise, class_name: 'PxHotStore',
                             source: :px_hot_store
    end)
  end

  after(:all) do
    %w[PxHotCustomer PxHotFranchise PxHotStore].each { |c| Object.send(:remove_const, c) }
  end

  let(:customer) { PxHotCustomer.new }

  describe 'setter' do
    it 'raises ReadonlyAssociation' do
      expect { customer.px_hot_store = PxHotStore.new }.to \
        raise_error(Mongoid::Errors::ReadonlyAssociation)
    end
  end

  describe '.eager_loader' do
    it 'returns a HasOneThrough::Eager' do
      assoc = PxHotCustomer.relations['px_hot_store']
      result = described_class.eager_loader([ assoc ], [])
      expect(result).to be_a(Mongoid::Association::Referenced::HasOneThrough::Eager)
    end
  end

  describe '.embedded?' do
    it 'returns false' do
      expect(described_class.embedded?).to be false
    end
  end
end
