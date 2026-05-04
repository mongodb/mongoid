# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Association::Referenced::HasOneThrough::Eager do
  before(:all) do
    Object.const_set(:EgCustomer, Class.new do
      include Mongoid::Document

      store_in collection: 'eg_customers'
      has_one :eg_franchise, class_name: 'EgFranchise', inverse_of: :eg_customer
      has_one :eg_store, through: :eg_franchise, class_name: 'EgStore'
    end)
    Object.const_set(:EgFranchise, Class.new do
      include Mongoid::Document

      store_in collection: 'eg_franchises'
      belongs_to :eg_customer, class_name: 'EgCustomer'
      has_one :eg_store, class_name: 'EgStore', inverse_of: :eg_franchise
    end)
    Object.const_set(:EgStore, Class.new do
      include Mongoid::Document

      store_in collection: 'eg_stores'
      belongs_to :eg_franchise, class_name: 'EgFranchise'
    end)
  end

  after(:all) do
    %w[EgCustomer EgFranchise EgStore].each { |c| Object.send(:remove_const, c) }
  end

  before { [ EgCustomer, EgFranchise, EgStore ].each(&:delete_all) }

  it 'preloads the through association for multiple owners' do
    c1 = EgCustomer.create!
    c2 = EgCustomer.create!
    f1 = EgFranchise.create!(eg_customer: c1)
    f2 = EgFranchise.create!(eg_customer: c2)
    s1 = EgStore.create!(eg_franchise: f1)
    s2 = EgStore.create!(eg_franchise: f2)

    customers = EgCustomer.includes(:eg_store).to_a
    by_id = customers.index_by(&:id)

    expect(by_id[c1.id].eg_store).to eq(s1)
    expect(by_id[c2.id].eg_store).to eq(s2)
  end

  it 'sets nil on owners without a store' do
    lone = EgCustomer.create!
    EgFranchise.create!(eg_customer: lone) # franchise but no store

    customers = EgCustomer.includes(:eg_store).to_a
    loaded = customers.find { |c| c.id == lone.id }
    expect(loaded.eg_store).to be_nil
  end
end
