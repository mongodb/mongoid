# frozen_string_literal: true

require 'spec_helper'

describe 'Short-circuit query optimization (MONGOID-5030)' do
  before { Band.create!(name: 'Depeche Mode') }

  describe 'allow_short_circuit_queries config option' do
    it 'defaults to false' do
      expect(Mongoid.allow_short_circuit_queries).to be false
    end
  end

  context 'when allow_short_circuit_queries is false (default)' do
    config_override :allow_short_circuit_queries, false

    describe 'a criteria with $in: []' do
      let(:criteria) { Band.in(name: []) }

      it 'uses the Mongo context (no short-circuit)' do
        expect(criteria.context).to be_a(Mongoid::Contextual::Mongo)
      end

      it 'issues a query to the database' do
        expect_query(1) { criteria.to_a }
      end
    end
  end

  context 'when allow_short_circuit_queries is true' do
    config_override :allow_short_circuit_queries, true

    describe 'a criteria with $in: []' do
      let(:criteria) { Band.in(name: []) }

      it 'uses the None context (short-circuits)' do
        expect(criteria.context).to be_a(Mongoid::Contextual::None)
      end

      it 'returns an empty array without querying the database' do
        expect_no_queries { expect(criteria.to_a).to eq([]) }
      end

      it 'returns zero for count without querying the database' do
        expect_no_queries { expect(criteria.count).to eq(0) }
      end

      it 'returns nil for first without querying the database' do
        expect_no_queries { expect(criteria.first).to be_nil }
      end

      it 'returns nil for last without querying the database' do
        expect_no_queries { expect(criteria.last).to be_nil }
      end
    end

    describe 'a criteria built with where($in: [])' do
      let(:criteria) { Band.where(name: { '$in' => [] }) }

      it 'uses the None context (short-circuits)' do
        expect(criteria.context).to be_a(Mongoid::Contextual::None)
      end

      it 'issues no database query' do
        expect_no_queries { criteria.to_a }
      end
    end

    describe 'a criteria with multiple conditions where one has $in: []' do
      let(:criteria) { Band.where(active: true).in(name: []) }

      it 'uses the None context (short-circuits)' do
        expect(criteria.context).to be_a(Mongoid::Contextual::None)
      end

      it 'issues no database query' do
        expect_no_queries { criteria.to_a }
      end
    end

    describe 'chained .in calls on the same field' do
      # Mongoid puts the second .in inside $and rather than intersecting at the
      # top level, so this does NOT short-circuit (treated as nested condition).
      let(:criteria) { Band.in(name: %w[A B]).in(name: %w[C D]) }

      it 'uses the Mongo context (no short-circuit for nested conditions)' do
        expect(criteria.context).to be_a(Mongoid::Contextual::Mongo)
      end

      it 'issues a query to the database' do
        expect_query(1) { criteria.to_a }
      end
    end

    describe 'a criteria with a non-empty $in' do
      let(:criteria) { Band.in(name: [ 'Depeche Mode' ]) }

      it 'uses the Mongo context (no short-circuit)' do
        expect(criteria.context).to be_a(Mongoid::Contextual::Mongo)
      end

      it 'issues a query and returns matching results' do
        expect_query(1) { expect(criteria.map(&:name)).to eq([ 'Depeche Mode' ]) }
      end
    end

    describe 'a criteria with no $in condition' do
      let(:criteria) { Band.where(name: 'Depeche Mode') }

      it 'uses the Mongo context (no short-circuit)' do
        expect(criteria.context).to be_a(Mongoid::Contextual::Mongo)
      end

      it 'issues a query to the database' do
        expect_query(1) { criteria.to_a }
      end
    end

    describe 'a nested $in: [] inside $and (out of scope, not short-circuited)' do
      let(:criteria) { Band.where('$and' => [ { 'name' => { '$in' => [] } } ]) }

      it 'uses the Mongo context (no short-circuit for nested conditions)' do
        expect(criteria.context).to be_a(Mongoid::Contextual::Mongo)
      end

      it 'issues a query to the database' do
        expect_query(1) { criteria.to_a }
      end
    end

    describe 'chainability after short-circuit' do
      it 'can chain further conditions on the short-circuited criteria and issues no query' do
        result = Band.in(name: []).where(active: true)
        expect(result).to be_a(Mongoid::Criteria)
        expect_no_queries { expect(result.to_a).to eq([]) }
      end
    end
  end
end
