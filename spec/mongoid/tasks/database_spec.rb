require "spec_helper"

describe "Mongoid::Tasks::Database" do

  let(:logger) do
    double("logger").tap do |log|
      allow(log).to receive(:info)
    end
  end

  before do
    allow(Mongoid::Tasks::Database).to receive(:logger).and_return(logger)
  end

  let(:models) do
    [ User, Account, Address, Draft ]
  end

  describe ".create_indexes" do

    let!(:klass) do
      User
    end

    let(:indexes) do
      Mongoid::Tasks::Database.create_indexes(models)
    end

    context "with ordinary Rails models" do

      it "creates the indexes for the models" do
        expect(klass).to receive(:create_indexes).once
        indexes
      end
    end

    context "with a model without indexes" do

      let(:klass) do
        Account
      end

      it "does nothing" do
        expect(klass).to receive(:create_indexes).never
        indexes
      end
    end

    context "when an exception is raised" do

      it "is not swallowed" do
        expect(klass).to receive(:create_indexes).and_raise(ArgumentError)
        expect { indexes }.to raise_error(ArgumentError)
      end
    end

    context "when index is defined on embedded model" do

      let!(:klass) do
        Address
      end

      before do
        klass.index(street: 1)
      end

      it "does nothing, but logging" do
        expect(klass).to receive(:create_indexes).never
        indexes
      end
    end

    context "when index is defined on self-embedded (cyclic) model" do

      let(:klass) do
        Draft
      end

      it "creates the indexes for the models" do
        expect(klass).to receive(:create_indexes).once
        indexes
      end
    end
  end

  describe ".undefined_indexes" do

    before(:each) do
      Mongoid::Tasks::Database.create_indexes(models)
    end

    let(:indexes) do
      Mongoid::Tasks::Database.undefined_indexes(models)
    end

    it "returns the removed indexes" do
      expect(indexes).to be_empty
    end

    context "with extra index on model collection" do

      before(:each) do
        User.collection.indexes.create_one(account_expires: 1)
      end

      let(:names) do
        indexes[User].map{ |index| index['name'] }
      end

      it "should have single index returned" do
        expect(names).to eq(['account_expires_1'])
      end
    end
  end

  describe ".remove_undefined_indexes" do

    let(:indexes) do
      User.collection.indexes
    end

    before(:each) do
      Mongoid::Tasks::Database.create_indexes(models)
      indexes.create_one(account_expires: 1)
      Mongoid::Tasks::Database.remove_undefined_indexes(models)
    end

    let(:removed_indexes) do
      Mongoid::Tasks::Database.undefined_indexes(models)
    end

    it "returns the removed indexes" do
      expect(removed_indexes).to be_empty
    end

    context 'when the index is a text index', if: non_legacy_server? do

      before do
        class Band
          index origin: Mongo::Index::TEXT
        end
        Mongoid::Tasks::Database.create_indexes([Band])
        Mongoid::Tasks::Database.remove_undefined_indexes([Band])
      end

      let(:indexes) do
        Band.collection.indexes
      end

      it 'does not delete the text index' do
        expect(indexes.find { |i| i['name'] == 'origin_text' }).not_to be_nil
      end
    end
  end

  describe ".remove_indexes" do

    let!(:klass) do
      User
    end

    let(:indexes) do
      klass.collection.indexes
    end

    before :each do
      Mongoid::Tasks::Database.create_indexes(models)
      Mongoid::Tasks::Database.remove_indexes(models)
    end

    it "removes indexes from klass" do
      expect(indexes.reject{ |doc| doc["name"] == "_id_" }).to be_empty
    end

    it "leaves _id index untouched" do
      expect(indexes.select{ |doc| doc["name"] == "_id_" }).to_not be_empty
    end
  end
end
