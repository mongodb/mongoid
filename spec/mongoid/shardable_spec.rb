require "spec_helper"

describe Mongoid::Shardable do

  describe ".included" do

    let(:klass) do
      Class.new do
        include Mongoid::Shardable
      end
    end

    it "adds an shard_key_fields accessor" do
      expect(klass).to respond_to(:shard_key_fields)
    end

    it "defaults shard_key_fields to an empty array" do
      expect(klass.shard_key_fields).to be_empty
    end
  end

  describe ".shard_key" do

    let(:klass) do
      Band
    end

    before do
      Band.shard_key(:name)
    end

    it "specifies a shard key on the collection" do
      expect(klass.shard_key_fields).to eq([:name])
    end

    context 'when a relation is used as the shard key' do

      let(:klass) do
        Game
      end

      before do
        Game.shard_key(:person)
      end

      it "converts the shard key to the foreign key field" do
        expect(klass.shard_key_fields).to eq([:person_id])
      end
    end
  end

  describe '#shard_key_selector' do
    subject { instance.shard_key_selector }
    let(:klass) { Band }
    let(:instance) { klass.new(name: name) }
    let(:name) { 'Jo' }

    before { klass.shard_key(:name) }

    it { is_expected.to eq({ 'name' => name }) }

    context 'changing shard_key value on persisted record' do
      let(:instance) { klass.create(name: name) }

      before do
        instance.name = 'Izi4'
      end

      it { is_expected.to eq({ 'name' => name }) }
    end
  end
end
