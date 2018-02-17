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
    let(:value) { 'a-brand-name' }

    before { klass.shard_key(:name) }

    context 'when record is new' do
      let(:instance) { klass.new(name: value) }

      it { is_expected.to eq({ 'name' => value }) }

      context 'changing shard key value' do
        let(:new_value) { 'a-new-value' }

        before do
          instance.name = new_value
        end

        it { is_expected.to eq({ 'name' => new_value }) }
      end
    end

    context 'when record is persisted' do
      let(:instance) { klass.create(name: value) }

      it { is_expected.to eq({ 'name' => value }) }

      context 'changing shard key value' do
        let(:new_value) { 'a-new-value' }

        before do
          instance.name = new_value
        end

        it { is_expected.to eq({ 'name' => value }) }
      end
    end
  end
end
