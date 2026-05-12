# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Changeset::Entry do
  subject(:entry) do
    described_class.new(
      type: :update,
      collection: collection,
      selector: selector,
      payload: payload,
      document: document,
      session: nil
    )
  end

  let(:collection) { instance_double(Mongo::Collection) }
  let(:selector) { { '_id' => BSON::ObjectId.new } }
  let(:payload) { { '$set' => { 'name' => 'Tool' } } }
  let(:document) { instance_double(Mongoid::Document) }

  it 'exposes type' do
    expect(entry.type).to eq(:update)
  end

  it 'exposes collection' do
    expect(entry.collection).to eq(collection)
  end

  it 'exposes selector' do
    expect(entry.selector).to eq(selector)
  end

  it 'exposes payload' do
    expect(entry.payload).to eq(payload)
  end

  it 'exposes document' do
    expect(entry.document).to eq(document)
  end

  it 'exposes session' do
    expect(entry.session).to be_nil
  end

  context 'when document is nil (criteria-level entry)' do
    subject(:entry) do
      described_class.new(
        type: :update_many,
        collection: collection,
        selector: { 'active' => true },
        payload: { '$set' => { 'archived' => true } },
        document: nil,
        session: nil
      )
    end

    it 'allows nil document' do
      expect(entry.document).to be_nil
    end
  end
end
