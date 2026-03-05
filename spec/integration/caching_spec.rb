# frozen_string_literal: true

require 'spec_helper'

describe 'caching integration tests' do
  let(:store) { ActiveSupport::Cache::MemoryStore.new }

  context 'without updated_at' do
    let(:model1) { Person.create }
    let(:model2) { Person.create }

    before do
      store.write(model1, 'model1')
      store.write(model2, 'model2')
    end

    it 'uses a unique key' do
      expect(store.read(model1)).to be == 'model1'
      expect(store.read(model2)).to be == 'model2'
    end

    context 'when updating' do
      before do
        model1.update title: 'updated'
        model2.update title: 'updated'
      end

      let(:reloaded_model1) { Person.find(model1.id) }
      let(:reloaded_model2) { Person.find(model2.id) }

      it 'still finds the models' do
        expect(store.read(reloaded_model1)).to be == 'model1'
        expect(store.read(reloaded_model2)).to be == 'model2'
      end
    end
  end

  context 'with updated_at' do
    let(:model1) { Dokument.create }
    let(:model2) { Dokument.create }

    before do
      store.write(model1, 'model1')
      store.write(model2, 'model2')
    end

    it 'uses a unique key' do
      expect(store.read(model1)).to be == 'model1'
      expect(store.read(model2)).to be == 'model2'
    end

    context 'when updating' do
      before do
        model1.update title: 'updated'
        model2.update title: 'updated'
      end

      let(:reloaded_model1) { Dokument.find(model1.id) }
      let(:reloaded_model2) { Dokument.find(model2.id) }

      it 'does not find the models' do
        # because the update caused the cache_version to change
        expect(store.read(reloaded_model1)).to be_nil
        expect(store.read(reloaded_model2)).to be_nil
      end
    end
  end
end
