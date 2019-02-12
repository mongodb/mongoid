# frozen_string_literal: true

require "spec_helper"
require_relative './has_and_belongs_to_many_models'

describe Mongoid::Association::Referenced::HasAndBelongsToMany do
  context 'when projecting with #only' do
    before do
      contract = HabtmmContract.create!(item: 'foo')
      contract.signatures << HabtmmSignature.create!(contracts: [contract], name: 'Dave', year: 2019)
      contract.save!
    end

    let(:contract) do
      HabtmmContract.where(item: 'foo').only(:signature_ids,
        'signatures._id', 'signatures.name').first
    end

    let(:signature) { contract.signatures.first }

    it 'populates specified fields only' do
      pending 'https://jira.mongodb.org/browse/MONGOID-4704'

      expect(signature.name).to eq('Dave')
      # has a default value specified in the model
      expect do
        signature.year
      end.to raise_error(ActiveModel::MissingAttributeError)
      expect(signature.attributes.keys).to eq(['_id', 'name'])
    end

    # Delete this test when https://jira.mongodb.org/browse/MONGOID-4704 is
    # implemented and above test is unpended
    it 'fetches all fields' do
      expect(signature.name).to eq('Dave')
      expect(signature.year).to eq(2019)
    end
  end
end
