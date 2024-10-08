# frozen_string_literal:true

require 'spec_helper'

describe Mongoid::Criteria::Queryable do
  let(:db) do
    Mongoid.default_client.database.name
  end

  let(:common_attributes) do
    {
      :'$db' => db,
      find: 'bands'
    }
  end

  shared_examples 'translatable to mql' do
    it 'returns mql' do
      expect(criteria.to_mql).to eq(
        common_attributes.merge(mql_attributes)
      )
    end
  end

  describe '#to_mql' do
    context 'when simple where' do
      let(:criteria) do
        Band.where(name: 'Depeche Mode')
      end

      let(:mql_attributes) do
        {
          filter:  { 'name' => 'Depeche Mode' }
        }
      end

      it_behaves_like 'translatable to mql'
    end

    context 'with storage field name' do
      let(:criteria) do
        Band.where(:origin.ne => 'UK')
            .in(years: [ 1995, 1996 ])
      end

      let(:mql_attributes) do
        {
          filter:  {
            'origin' =>  { '$ne' => 'UK' },
            'y' => { '$in' => [ 1995, 1996 ] }
          }
        }
      end

      it_behaves_like 'translatable to mql'
    end

    context 'with alias attribute' do
      let(:criteria) do
        Band.where(d: true)
      end

      let(:mql_attributes) do
        {
          filter:  { 'deleted' => true }
        }
      end

      it_behaves_like 'translatable to mql'
    end

    context 'with options' do
      let(:criteria) do
        Band.where(genres: ['rock', 'hip-hop']).order(founded: 1).limit(100).skip(200)
      end

      let(:mql_attributes) do
        {
          filter:  { "genres" => [ "rock", "hip-hop" ] },
          limit:  100,
          skip:  200,
          sort:  { 'founded' => 1 }
        }
      end

      it_behaves_like 'translatable to mql'
    end
  end
end
