# frozen_string_literal: true

require "spec_helper"

class CollectionConfigurableCapped
  include Mongoid::Document

  store_in collection_options: {
    capped: true,
    size: 10000
  }
end

class CollectionConfigurableUnknownOptions
  include Mongoid::Document

  store_in collection_options: {
    i_am_not_an_option: true,
    let_me: { raise: true }
  }
end

describe Mongoid::CollectionConfigurable do
  before(:each) do
    [
      CollectionConfigurableCapped,
      CollectionConfigurableUnknownOptions
    ].each do |klaz|
      klaz.collection.drop
    end
  end

  context 'when collection does not exist' do
    context 'with an unknown collection options' do
      let(:subject) do
        CollectionConfigurableUnknownOptions
      end

      it 'creates the collection' do
        subject.create_collection
        expect(
          subject.collection.database.list_collections(filter: { name: subject.collection_name.to_s })
        ).not_to be_empty
      end
    end

    context 'with supported options' do
      let(:subject) do
        CollectionConfigurableCapped
      end

      it 'creates the collection' do
        subject.create_collection
        expect(
          subject.collection.database.list_collections(filter: { name: subject.collection_name.to_s })
        ).not_to be_empty
      end
    end

    context 'with unsupported options' do

      let(:subject) do
        CollectionConfigurableCapped
      end

      before do
        expect_any_instance_of(Mongo::Collection)
          .to receive(:create)
          .with({ capped: true, size: 10000 })
          .and_raise(Mongo::Error::OperationFailure)
      end

      it 'raises an error' do
        expect do
          subject.create_collection
        end.to raise_error(Mongoid::Errors::CreateCollection)
      end
    end
  end

  context 'when collection exists' do
    let(:subject) do
      CollectionConfigurableCapped
    end

    let(:logger) do
      double("logger").tap do |log|
        expect(log).to receive(:info).once.with(/Collection '#{subject.collection_name}' already exist/)
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
end
