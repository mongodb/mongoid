# frozen_string_literal:true

require 'spec_helper'

describe Mongoid::Criteria::Queryable do
  let(:db) do
    Mongoid.default_client.database.name
  end

  let(:collection) do
    Band.collection_name.to_s
  end

  shared_examples 'translatable to mql' do
    it 'returns mql' do
      expect(criteria.to_mql).to eq(mql)
    end
  end

  describe '#to_mql' do
    context 'when simple where' do
      let(:criteria) do
        Band.where(name: 'Depeche Mode')
      end

      let(:mql) do
        {
          '$db': db,
          find: collection,
          filter: { 'name' => 'Depeche Mode' }
        }
      end

      it_behaves_like 'translatable to mql'
    end

    context 'with storage field name' do
      let(:criteria) do
        Band.where(:origin.ne => 'UK')
            .in(years: [ 1995, 1996 ])
      end

      let(:mql) do
        {
          '$db': db,
          find: collection,
          filter: {
            'origin' => { '$ne' => 'UK' },
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

      let(:mql) do
        {
          '$db': db,
          find: collection,
          filter: { 'deleted' => true }
        }
      end

      it_behaves_like 'translatable to mql'
    end

    context 'with options' do
      let(:criteria) do
        Band.where(genres: %w[rock hip-hop]).order(founded: 1).limit(100).skip(200)
      end

      let(:mql) do
        {
          '$db': db,
          find: collection,
          filter: { 'genres' => %w[rock hip-hop] },
          limit: 100,
          skip: 200,
          sort: { 'founded' => 1 }
        }
      end

      it_behaves_like 'translatable to mql'
    end
  end
end
