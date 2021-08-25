# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Document do
  context 'when including class uses delegate' do
    let(:patient) do
      DelegatingPatient.new(
        email: Email.new(address: 'test@example.com'),
      )
    end

    it 'works for instance level delegation' do
      patient.address.should == 'test@example.com'
    end

    it 'works for class level delegation' do
      DelegatingPatient.default_client.should be Mongoid.default_client
    end
  end

  context 'when id is unaliased' do
    it 'persists separate id and _id values' do
      shirt = Shirt.create!(id: 'hello', _id: 'foo')
      shirt = Shirt.find(shirt._id)
      shirt.id.should == 'hello'
      shirt._id.should == 'foo'
    end
  end

  describe '#reload' do
    context 'when changing shard key value' do
      require_topology :sharded

      let(:profile) do
        # Profile shard_key :name
        Profile.create!(name: "Alice")
      end

      it "successfully reloads the document after saving an update to the sharded field" do
        expect(profile.name).to eq("Alice")
        profile.name = "Bob"
        profile.save!

        profile.reload

        expect(profile.name).to eq("Bob")
      end
    end
  end
end
