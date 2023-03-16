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
          expect(SmProducer.shard_key_fields).to be == %i(age gender)
        end

        it 'sets shard config' do
          expect(SmProducer.shard_config).to be == {
            key: {age: 1, gender: 'hashed'},
            options: {
              unique: true,
              numInitialChunks: 2,
            },
          }
        end

        it 'keeps hashed as string' do
          expect(SmProducer.shard_config[:key][:gender]).to be == 'hashed'
        end
      end

      context 'with string value' do
        it 'sets shard key fields to symbol value' do
          expect(SmActor.shard_key_fields).to be == %i(age gender hello)
        end

        it 'sets shard config' do
          expect(SmActor.shard_config).to be == {
            key: {age: 1, gender: 'hashed', hello: 'hashed'},
            options: {},
          }
        end

        it 'sets hashed to string' do
          expect(SmActor.shard_config[:key][:gender]).to be == 'hashed'
        end
      end

      context 'when passed association name' do
        it 'uses foreign key as shard key in shard config' do
          expect(SmDriver.shard_config).to be == {
            key: {age: 1, agency_id: 'hashed'},
            options: {},
          }
        end

        it 'uses foreign key as shard key in shard key fields' do
          expect(SmDriver.shard_key_fields).to be == %i(age agency_id)
        end
      end
    end

    context 'when shorthand syntax is used' do
      context 'with symbol value' do
        it 'sets shard key fields to symbol value' do
          expect(SmMovie.shard_key_fields).to be == %i(year)
        end
      end

      context 'with string value' do
        it 'sets shard key fields to symbol value' do
          expect(SmTrailer.shard_key_fields).to be == %i(year)
        end
      end

      context 'when passed association name' do
        it 'uses foreign key as shard key in shard config' do
          expect(SmDirector.shard_config).to be == {
            key: {agency_id: 1},
            options: {},
          }
        end

        it 'uses foreign key as shard key in shard key fields' do
          expect(SmDirector.shard_key_fields).to be == %i(agency_id)
        end
      end
    end
  end

  describe '#shard_key_selector' do
    subject { instance.shard_key_selector }
    
    context 'when key is an immediate attribute' do
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

          it { is_expected.to eq({ 'name' => new_value }) }
        end
      end
    end

    context 'when key is an embedded attribute' do
      let(:klass) { SmReview }
      let(:value) { 'Arthur Conan Doyle' }
      let(:key)   { 'author.name' }

      context 'when record is new' do
        let(:instance) { klass.new(author: { name: value }) }

        it { is_expected.to eq({ key => value }) }

        context 'changing shard key value' do
          let(:new_value) { 'Jules Verne' }

          before do
            instance.author.name = new_value
          end

          it { is_expected.to eq({ key => new_value }) }
        end
      end

      context 'when record is persisted' do
        let(:instance) { klass.create!(author: { name: value }) }

        it { is_expected.to eq({ key => value }) }

        context 'changing shard key value' do
          let(:new_value) { 'Jules Verne' }

          before do
            instance.author.name = new_value
          end

          it { is_expected.to eq({ 'author.name' => new_value }) }
        end
      end
    end
  end

  describe '#shard_key_selector_in_db' do
    subject { instance.shard_key_selector_in_db }

    context 'when key is an immediate attribute' do
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

    context 'when key is an embedded attribute' do
      let(:klass) { SmReview }
      let(:value) { 'Arthur Conan Doyle' }
      let(:key)   { 'author.name' }

      context 'when record is new' do
        let(:instance) { klass.new(author: { name: value }) }

        it { is_expected.to eq({ key => value }) }

        context 'changing shard key value' do
          let(:new_value) { 'Jules Verne' }

          before do
            instance.author.name = new_value
          end

          it { is_expected.to eq({ key => new_value }) }
        end
      end

      context 'when record is persisted' do
        let(:instance) { klass.create!(author: { name: value }) }

        it { is_expected.to eq({ key => value }) }

        context 'changing shard key value' do
          let(:new_value) { 'Jules Verne' }

          before do
            instance.author.name = new_value
          end

          it { is_expected.to eq({ key => value }) }
        end

        context "when record is not found" do
          let!(:instance) { klass.create!(author: { name: value }) }
  
          before do
            instance.destroy
          end
  
          it "raises a DocumentNotFound error with the shard key in the description on reload" do
            expect do
              instance.reload
            end.to raise_error(Mongoid::Errors::DocumentNotFound, /Document not found for class SmReview with id #{instance.id.to_s} and shard key author.name: Arthur Conan Doyle./)
          end
        end
      end
    end
  end
end
