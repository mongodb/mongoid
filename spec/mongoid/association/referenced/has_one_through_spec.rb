# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Association::Referenced::HasOneThrough do
  # Model setup:
  #   HotCustomer  has_one :hot_franchise
  #   HotCustomer  has_one :hot_store, through: :hot_franchise, source: :depot
  #   HotFranchise has_one :depot (class HotStore)

  before(:all) do
    Object.const_set(:HotStore, Class.new do
      include Mongoid::Document

      field :hot_franchise_id, type: BSON::ObjectId
    end)
    Object.const_set(:HotFranchise, Class.new do
      include Mongoid::Document

      field :hot_customer_id, type: BSON::ObjectId
      has_one :depot, class_name: 'HotStore', inverse_of: :hot_franchise
    end)
    Object.const_set(:HotCustomer, Class.new do
      include Mongoid::Document

      has_one :hot_franchise, class_name: 'HotFranchise', inverse_of: :hot_customer
      has_one :hot_store, through: :hot_franchise,
                          class_name: 'HotStore', source: :depot
    end)
  end

  after(:all) do
    %w[HotCustomer HotFranchise HotStore].each { |c| Object.send(:remove_const, c) }
  end

  let(:assoc) { HotCustomer.relations['hot_store'] }

  describe '#through_association' do
    it 'returns the intermediate association metadata' do
      expect(assoc.through_association).to eq(HotCustomer.relations['hot_franchise'])
    end
  end

  describe '#source_association' do
    it 'returns the :depot association on HotFranchise' do
      expect(assoc.source_association).to eq(HotFranchise.relations['depot'])
    end
  end

  describe '#embedded?' do
    it 'returns false' do
      expect(assoc.embedded?).to be false
    end
  end

  describe 'VALID_OPTIONS' do
    it 'accepts :through' do
      expect { HotCustomer.has_one(:foo, through: :hot_franchise) }.not_to raise_error
    end

    it 'accepts :source' do
      expect { HotCustomer.has_one(:bar, through: :hot_franchise, source: :depot) }.not_to raise_error
    end

    it 'rejects unknown options at definition time' do
      expect do
        HotCustomer.has_one(:baz, through: :hot_franchise, bogus_option: true)
      end.to raise_error(Mongoid::Errors::InvalidRelationOption)
    end
  end

  describe '#criteria' do
    it 'returns nil when the intermediate is nil' do
      customer = HotCustomer.new
      allow(customer).to receive(:hot_franchise).and_return(nil)
      expect(assoc.criteria(customer)).to be_nil
    end

    it 'delegates to the source association on the intermediate' do
      franchise = HotFranchise.new
      store     = HotStore.new
      customer  = HotCustomer.new
      allow(customer).to receive(:hot_franchise).and_return(franchise)
      allow(franchise).to receive(:depot).and_return(store)
      expect(assoc.criteria(customer)).to eq(store)
    end
  end
end
