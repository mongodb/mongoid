# frozen_string_literal: true

require "spec_helper"

describe Mongoid::CollectionConfigurable do

  before(:all) do
    class CollectionConfigurableValidOptions
      include Mongoid::Document

      store_in collection_options: {
        capped: true,
        size: 2560
      }
    end

    class CollectionConfigurableUnknownOptions
      include Mongoid::Document

      store_in collection_options: {
        i_am_not_an_option: true,
        let_me: { fail: true }
      }
    end

    class CollectionConfigurableInvalidOptions
      include Mongoid::Document

      store_in collection_options: {
        capped: true
        # Creating a capped collection requires `size` field; therefore,
        # an attempt to create a collection with only `capped : true` option
        # fails.
      }
    end
  end

  after(:all) do
    Mongoid.deregister_model(CollectionConfigurableValidOptions)
    Object.send(:remove_const, :CollectionConfigurableValidOptions)
    Mongoid.deregister_model(CollectionConfigurableUnknownOptions)
    Object.send(:remove_const, :CollectionConfigurableUnknownOptions)
    Mongoid.deregister_model(CollectionConfigurableInvalidOptions)
    Object.send(:remove_const, :CollectionConfigurableInvalidOptions)
  end

  after(:each) do
    [
      CollectionConfigurableValidOptions,
      CollectionConfigurableUnknownOptions
    ].each do |klazz|
      klazz.collection.drop
    end
  end

  context 'when collection does not exist' do
    context 'with valid options' do
      let(:subject) do
        CollectionConfigurableValidOptions
      end

      before(:each) do
        subject.create_collection
      end

      let(:coll_options) do
        subject.collection.database.list_collections(filter: { name: subject.collection_name.to_s }).first
      end

      it 'creates the collection' do
        expect(coll_options).not_to be_nil
      end

      it 'passes collection options' do
        expect(coll_options.dig('options', 'capped')).to eq(true)
        expect(coll_options.dig('options', 'size')).to eq(2560)
      end
    end

    context 'with an unknown collection options' do
      let(:subject) do
        CollectionConfigurableUnknownOptions
      end

      it 'raises an error' do
        expect do
          subject.create_collection
        end.to raise_error(Mongoid::Errors::CreateCollectionFailure)
      end
    end

    context 'with invalid options' do
      let(:subject) do
        CollectionConfigurableInvalidOptions
      end

      it 'raises an error' do
        expect do
          subject.create_collection
        end.to raise_error(Mongoid::Errors::CreateCollectionFailure)
      end
    end
  end

  context 'when collection exists' do
    let(:subject) do
      CollectionConfigurableValidOptions
    end

    context 'when force is false' do
      let(:logger) do
        double("logger").tap do |log|
          expect(log).to receive(:debug).once.with(/Collection '#{subject.collection_name}' already exist/)
        end
      end

      before do
        allow(subject).to receive(:logger).and_return(logger)
        subject.collection.create
      end

      it 'logs a message' do
        subject.create_collection
      end
    end

    context 'when force is true' do
      let(:logger) do
        double("logger")
      end

      let(:coll_options) do
        subject.collection.database.list_collections(filter: { name: subject.collection_name.to_s }).first
      end

      before do
        allow(subject).to receive(:logger).and_return(logger)
        subject.collection.create
      end

      it 'does not log a message' do
        expect(logger).to receive(:debug).never.with(/Collection '#{subject.collection_name}' already exist/)
        subject.create_collection(force: true)
      end

      it 'creates the collection' do
        subject.create_collection(force: true)
        expect(coll_options).not_to be_nil
      end

      it 'passes collection options' do
        subject.create_collection(force: true)
        expect(coll_options.dig('options', 'capped')).to eq(true)
        expect(coll_options.dig('options', 'size')).to eq(2560)
      end
    end
  end
end
