# frozen_string_literal: true

require "spec_helper"
require_relative './shardable_models'

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

    context 'when full syntax is used' do
      context 'with symbol value' do
        it 'sets shard key fields to symbol value' do
          SmProducer.shard_key_fields.should == %i(age gender)
        end

        it 'sets shard config' do
          SmProducer.shard_config.should == {
            key: {age: 1, gender: 'hashed'},
            options: {
              unique: true,
              numInitialChunks: 2,
            },
          }
        end

        it 'keeps hashed as string' do
          SmProducer.shard_config[:key][:gender].should == 'hashed'
        end
      end

      context 'with string value' do
        it 'sets shard key fields to symbol value' do
          SmActor.shard_key_fields.should == %i(age gender hello)
        end

        it 'sets shard config' do
          SmActor.shard_config.should == {
            key: {age: 1, gender: 'hashed', hello: 'hashed'},
            options: {},
          }
        end

        it 'sets hashed to string' do
          SmActor.shard_config[:key][:gender].should == 'hashed'
        end
      end

      context 'when passed association name' do
        it 'uses foreign key as shard key in shard config' do
          SmDriver.shard_config.should == {
            key: {age: 1, agency_id: 'hashed'},
            options: {},
          }
        end

        it 'uses foreign key as shard key in shard key fields' do
          SmDriver.shard_key_fields.should == %i(age agency_id)
        end
      end
    end

    context 'when shorthand syntax is used' do
      context 'with symbol value' do
        it 'sets shard key fields to symbol value' do
          SmMovie.shard_key_fields.should == %i(year)
        end
      end

      context 'with string value' do
        it 'sets shard key fields to symbol value' do
          SmTrailer.shard_key_fields.should == %i(year)
        end
      end

      context 'when passed association name' do
        it 'uses foreign key as shard key in shard config' do
          SmDirector.shard_config.should == {
            key: {agency_id: 1},
            options: {},
          }
        end

        it 'uses foreign key as shard key in shard key fields' do
          SmDirector.shard_key_fields.should == %i(agency_id)
        end
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
      let(:instance) { klass.create!(name: value) }

      it { is_expected.to eq({ 'name' => value }) }

      context 'changing shard key value' do
        let(:new_value) { 'a-new-value' }

        before do
          instance.name = new_value
        end

        it 'uses the newly set shard key value' do
          subject.should == { 'name' => new_value }
        end
      end
    end
  end

  describe '#shard_key_selector_in_db' do
    subject { instance.shard_key_selector_in_db }
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

        it 'uses the existing shard key value' do
          subject.should == { 'name' => new_value }
        end
      end
    end

    context 'when record is persisted' do
      let(:instance) { klass.create!(name: value) }

      it { is_expected.to eq({ 'name' => value }) }

      context 'changing shard key value' do
        let(:new_value) { 'a-new-value' }

        before do
          instance.name = new_value
        end

        it { is_expected.to eq({ 'name' => value }) }
      end
    end

    context "when record is not found" do
      let!(:instance) { klass.create!(name: value) }

      before do
        instance.destroy
      end

      it "raises a DocumentNotFound error with the shard key in the description on reload" do
        expect do
          instance.reload
        end.to raise_error(Mongoid::Errors::DocumentNotFound, /Document not found for class Band with id #{instance.id.to_s} and shard key name: a-brand-name./)
      end
    end
  end
end
