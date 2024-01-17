# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::AtomicUpdatePreparer do
  describe '#prepare' do
    let(:prepared) { described_class.prepare(hash, Band) }

    context 'when the hash already contains $set' do
      context 'when the $set is first' do
        let(:hash) do
          { '$set' => { name: 'Tool' }, likes: 10, '$inc' => { plays: 1 } }
        end

        it 'moves the non hash values under the provided key' do
          expect(prepared).to eq(
            '$set' => { 'name' => 'Tool', 'likes' => 10 },
            '$inc' => { 'plays' => 1 }
          )
        end
      end

      context 'when the $set is not first' do
        let(:hash) do
          { likes: 10, '$inc' => { plays: 1 }, '$set' => { name: 'Tool' } }
        end

        it 'moves the non hash values under the provided key' do
          expect(prepared).to eq(
            '$set' => { 'likes' => 10, 'name' => 'Tool' },
            '$inc' => { 'plays' => 1 }
          )
        end
      end
    end

    context 'when the hash does not contain $set' do
      let(:hash) do
        { likes: 10, '$inc' => { plays: 1 }, name: 'Tool' }
      end

      it 'moves the non hash values under the provided key' do
        expect(prepared).to eq(
          '$set' => { 'likes' => 10, 'name' => 'Tool' },
          '$inc' => { 'plays' => 1 }
        )
      end
    end

    context 'when the hash contains $rename' do
      let(:hash) { { likes: 10, '$rename' => { old: 'new' } } }

      it 'preserves the $rename operator' do
        expect(prepared).to eq(
          '$set' => { 'likes' => 10 },
          '$rename' => { 'old' => 'new' }
        )
      end
    end

    context 'when the hash contains $addToSet' do
      let(:hash) { { likes: 10, '$addToSet' => { list: 'new' } } }

      it 'preserves the $addToSet operator' do
        expect(prepared).to eq(
          '$set' => { 'likes' => 10 },
          '$addToSet' => { 'list' => 'new' }
        )
      end
    end

    context 'when the hash contains $push' do
      let(:hash) { { likes: 10, '$push' => { list: 14 } } }

      it 'preserves the $push operator' do
        expect(prepared).to eq(
          '$set' => { 'likes' => 10 },
          '$push' => { 'list' => 14 }
        )
      end
    end
  end
end
