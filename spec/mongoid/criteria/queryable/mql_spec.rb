# frozen_string_literal:true

require 'spec_helper'

describe Mongoid::Criteria::Queryable::MQL do
  describe '#to_mql' do
    context 'when simple where' do
      let(:criteria) do
        Band.where(name: 'Depeche Mode')
      end

      it 'returns mql' do
        expect(criteria.to_mql).to eq(
          {
            find:  'bands',
            filter:  { 'name' => 'Depeche Mode' }
          }
        )
      end
    end

    context 'with storage field name' do
      let(:criteria) do
        Band.where(:origin.ne => 'UK')
            .in(years: [ 1995, 1996 ])
      end

      it 'returns mql' do
        expect(criteria.to_mql).to eq(
          {
            find:  'bands',
            filter:  {
              'origin' =>  { '$ne' => 'UK' },
              'y' => { '$in' => [ 1995, 1996 ] }
            }
          }
        )
      end
    end

    context 'with alias attribute' do
      let(:criteria) do
        Band.where(d: true)
      end

      it 'returns mql' do
        expect(criteria.to_mql).to eq(
          {
            find:  'bands',
            filter:  { 'deleted' => true }
          }
        )
      end
    end

    context 'with options' do
      let(:criteria) do
        Band.where(genres: ['rock', 'hip-hop']).order(founded: 1).limit(100).skip(200)
      end

      it 'returns mql' do
        expect(criteria.to_mql).to eq(
          {
            find:  'bands',
            filter:  { "genres" => [ "rock", "hip-hop" ] },
            limit:  100,
            skip:  200,
            sort:  { 'founded' => 1 }
          }
        )
      end
    end
  end
end
