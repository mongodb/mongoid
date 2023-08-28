# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Attributes::Embedded do
  describe '.traverse' do
    subject(:embedded) { described_class.traverse(attributes, path) }

    let(:path) { '100.name' }

    context 'when the attribute key is a string' do
      let(:attributes) { { '100' => { 'name' => 'hundred' } } }

      it 'retrieves an embedded value under the provided key' do
        expect(embedded).to eq 'hundred'
      end

      context 'when the value is false' do
        let(:attributes) { { '100' => { 'name' => false } } }

        it 'retrieves the embedded value under the provided key' do
          expect(embedded).to be false
        end
      end

      context 'when the value does not exist' do
        let(:attributes) { { '100' => { 0 => 'Please do not return this value!' } } }

        it 'returns nil' do
          expect(embedded).to be_nil
        end
      end
    end

    context 'when the attribute key is an integer' do
      let(:attributes) { { 100 => { 'name' => 'hundred' } } }

      it 'retrieves an embedded value under the provided key' do
        expect(embedded).to eq 'hundred'
      end
    end

    context 'when the attribute value is nil' do
      let(:attributes) { { 100 => { 'name' => nil } } }

      it 'returns nil' do
        expect(embedded).to be_nil
      end
    end

    context 'when both string and integer keys are present' do
      let(:attributes) { { '100' => { 'name' => 'Fred' }, 100 => { 'name' => 'Daphne' } } }

      it 'returns the string key value' do
        expect(embedded).to eq 'Fred'
      end

      context 'when the string key value is nil' do
        let(:attributes) { { '100' => nil, 100 => { 'name' => 'Daphne' } } }

        it 'returns nil' do
          expect(embedded).to be_nil
        end
      end
    end

    context 'when attributes is an array' do
      let(:attributes) do
        [ { 'name' => 'Fred' }, { 'name' => 'Daphne' }, { 'name' => 'Velma' }, { 'name' => 'Shaggy' } ]
      end
      let(:path) { '2.name' }

      it 'retrieves the nth value' do
        expect(embedded).to eq 'Velma'
      end

      context 'when the member does not exist' do
        let(:attributes) { [ { 'name' => 'Fred' }, { 'name' => 'Daphne' } ] }

        it 'returns nil' do
          expect(embedded).to be_nil
        end
      end
    end

    context 'when the path includes a scalar value' do
      let(:attributes) { { '100' => 'name' } }

      it 'returns nil' do
        expect(embedded).to be_nil
      end
    end

    context 'when the parent key is not present' do
      let(:attributes) { { '101' => { 'name' => 'hundred and one' } } }

      it 'returns nil' do
        expect(embedded).to be_nil
      end
    end

    context 'when the attributes are deeply nested' do
      let(:attributes) { { '100' => { 'name' => { 300 => %w[a b c] } } } }

      it 'retrieves the embedded subset of attributes' do
        expect(embedded).to eq(300 => %w[a b c])
      end

      context 'when the path is deeply nested' do
        let(:path) { '100.name.300.1' }

        it 'retrieves the embedded value' do
          expect(embedded).to eq 'b'
        end
      end
    end
  end
end
