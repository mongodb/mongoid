# frozen_string_literal: true
# rubocop:todo all

require 'spec_helper'

describe 'Hash field persistence' do
  let(:person) { Person.create!(field => value).reload }
  subject { person.send(field) }

  shared_examples_for 'Hash persistence behavior' do
    context 'when Hash with Strings' do
      let(:value) { { 'foo' => 'bar', 'baz' => 'qux' } }

      it 'returns a Hash' do
        expect(subject).to be_a Hash
        expect(subject).not_to be_a BSON::Document
      end

      it 'returns the keys and values as Strings' do
        expect(subject).to eq({ 'foo' => 'bar', 'baz' => 'qux' })
      end
    end

    context 'when Hash with Symbols' do
      let(:value) { { foo: :bar, baz: 'qux' } }

      it 'returns a Hash' do
        expect(subject).to be_a Hash
        expect(subject).not_to be_a BSON::Document
      end

      it 'returns the keys as Strings and values as Symbols' do
        expect(subject).to eq({ 'foo' => :bar, 'baz' => 'qux' })
      end
    end

    context 'when Hash with Integer keys' do
      let(:value) { { 1 => 'bar', 2 => 2, 3 => 3.1 } }

      it 'returns a Hash' do
        expect(subject).to be_a Hash
        expect(subject).not_to be_a BSON::Document
      end

      it 'returns the keys as Strings' do
        expect(subject).to eq({ '1' => 'bar', '2' => 2, '3' => 3.1 })
      end
    end

    context 'when Hash with nested Hash' do
      let(:value) { { outer: { inner: 'value' } } }

      it 'returns a Hash' do
        expect(subject).to be_a Hash
        expect(subject).not_to be_a BSON::Document
      end

      it 'returns the nested Hash as a Hash' do
        nested = subject['outer']
        expect(nested).to be_a Hash
        expect(nested).not_to be_a BSON::Document
      end

      it 'returns the keys as Strings' do
        expect(subject).to eq({ 'outer' => { 'inner' => 'value' } })
      end
    end

    context 'when Hash with mixed types' do
      let(:value) do
        {
          'name' => :test,
          2 => 3,
          count: 42,
          'created_at' => [
            { foo: 1 },
            true,
            2.1
          ]
        }
      end

      let(:expected) do
        {
          'name' => :test,
          '2' => 3,
          'count' => 42,
          'created_at' => [
            { 'foo' => 1 },
            true,
            2.1
          ]
        }
      end

      it { expect(subject).to eq(expected) }
    end

    context 'when Hash with Float key' do
      let(:value) { { 1.0 => 'bar' } }

      it 'raises a TypeError' do
        expect { subject }.to raise_error(BSON::Error::InvalidKey, /Float instances are not allowed/)
      end
    end

    context 'when Hash with Array key' do
      let(:value) { { %w[foo bar] => 'baz' } }

      it 'raises a TypeError' do
        expect { subject }.to raise_error(BSON::Error::InvalidKey, /Array instances are not allowed/)
      end
    end

    context 'when Hash with Hash key' do
      let(:value) { { { 'foo' => 'bar' } => 'baz' } }

      it 'raises a TypeError' do
        expect { subject }.to raise_error(BSON::Error::InvalidKey, /Hash instances are not allowed/)
      end
    end

    context 'when Hash with TrueClass key' do
      let(:value) { { true => 'baz' } }

      it 'raises a TypeError' do
        expect { subject }.to raise_error(BSON::Error::InvalidKey, /TrueClass instances are not allowed/)
      end
    end

    context 'when Hash with FalseClass key' do
      let(:value) { { false => 'baz' } }

      it 'raises a TypeError' do
        expect { subject }.to raise_error(BSON::Error::InvalidKey, /FalseClass instances are not allowed/)
      end
    end

    context 'when Hash with NilClass key' do
      let(:value) { { nil => 'baz' } }

      it 'raises a TypeError' do
        expect { subject }.to raise_error(BSON::Error::InvalidKey, /NilClass instances are not allowed/)
      end
    end

    context 'when Hash with BSON::ObjectId key' do
      let(:value) { { BSON::ObjectId('a' * 24) => 'bar' } }

      it 'raises a TypeError' do
        expect { subject }.to raise_error(BSON::Error::InvalidKey, /BSON::ObjectId instances are not allowed/)
      end
    end
  end

  context 'static field' do
    before do
      Person.field(:hash_testing, type: Hash, default: {}, overwrite: true)
    end

    after do
      Person.fields.delete('hash_testing')
    end

    let(:field) { :hash_testing }

    it_behaves_like 'Hash persistence behavior'
  end

  context 'dynamic field' do
    let(:field) { :hash_dynamic }

    it_behaves_like 'Hash persistence behavior'
  end
end
