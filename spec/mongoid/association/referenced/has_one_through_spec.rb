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

  describe ':through on an embedded association' do
    it 'raises InvalidRelationOption when through association is embedded' do
      embedded_owner = Class.new do
        include Mongoid::Document

        embeds_one :address
      end
      embedded_owner.has_one(:city, through: :address)
      expect do
        embedded_owner.relations['city'].through_association # triggers lazy validation
      end.to raise_error(Mongoid::Errors::InvalidRelationOption)
    end
  end

  context 'integration', :integration do
    before(:all) do
      Object.const_set(:IntCustomer, Class.new do
        include Mongoid::Document

        store_in collection: 'int_customers'
        has_one :int_franchise, class_name: 'IntFranchise', inverse_of: :int_customer
        # source: :depot exercises the :source option end-to-end
        has_one :int_store, through: :int_franchise, class_name: 'IntStore', source: :depot
      end)

      Object.const_set(:IntFranchise, Class.new do
        include Mongoid::Document

        store_in collection: 'int_franchises'
        field :int_customer_id, type: BSON::ObjectId
        belongs_to :int_customer, class_name: 'IntCustomer'
        has_one :depot, class_name: 'IntStore', inverse_of: :int_franchise
      end)

      Object.const_set(:IntStore, Class.new do
        include Mongoid::Document

        store_in collection: 'int_stores'
        field :int_franchise_id, type: BSON::ObjectId
        belongs_to :int_franchise, class_name: 'IntFranchise'
      end)
    end

    after(:all) do
      %w[IntCustomer IntFranchise IntStore].each { |c| Object.send(:remove_const, c) }
    end

    before { [ IntCustomer, IntFranchise, IntStore ].each(&:delete_all) }

    let!(:customer)  { IntCustomer.create! }
    let!(:franchise) { IntFranchise.create!(int_customer: customer) }
    let!(:store)     { IntStore.create!(int_franchise: franchise) }

    describe 'getter' do
      it 'returns the store via the franchise' do
        expect(customer.int_store).to eq(store)
      end

      it 'returns nil when the franchise is absent' do
        lone = IntCustomer.create!
        expect(lone.int_store).to be_nil
      end

      it 'returns cached value before reload and fresh value after' do
        first_store = customer.int_store # prime cache
        expect(first_store).to eq(store)

        new_store = IntStore.create!
        franchise.depot = new_store
        franchise.save!

        expect(customer.int_store).to eq(store) # cached — still old
        expect(customer.int_store(true)).to eq(new_store) # reloaded
      end
    end

    describe 'setter' do
      it 'raises ReadonlyAssociation' do
        expect { customer.int_store = IntStore.new }.to \
          raise_error(Mongoid::Errors::ReadonlyAssociation)
      end
    end
  end

  context 'with :source option resolving a differently-named association', :integration do
    before(:all) do
      Object.const_set(:SrcOrg, Class.new do
        include Mongoid::Document

        store_in collection: 'src_orgs'
        has_one :src_location, class_name: 'SrcLocation', inverse_of: :src_org
        has_one :src_hq, through: :src_location,
                         class_name: 'SrcBuilding', source: :src_main_building
      end)
      Object.const_set(:SrcLocation, Class.new do
        include Mongoid::Document

        store_in collection: 'src_locations'
        belongs_to :src_org, class_name: 'SrcOrg'
        has_one :src_main_building, class_name: 'SrcBuilding', inverse_of: :src_location
      end)
      Object.const_set(:SrcBuilding, Class.new do
        include Mongoid::Document

        store_in collection: 'src_buildings'
        belongs_to :src_location, class_name: 'SrcLocation'
      end)
    end

    after(:all) do
      %w[SrcOrg SrcLocation SrcBuilding].each { |c| Object.send(:remove_const, c) }
    end

    before { [ SrcOrg, SrcLocation, SrcBuilding ].each(&:delete_all) }

    it 'resolves the :source association on the intermediate' do
      org      = SrcOrg.create!
      location = SrcLocation.create!(src_org: org)
      building = SrcBuilding.create!(src_location: location)
      expect(org.src_hq).to eq(building)
    end
  end
end
