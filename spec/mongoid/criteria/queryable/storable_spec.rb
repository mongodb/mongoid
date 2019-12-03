# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Criteria::Queryable::Storable do

  let(:query) do
    Mongoid::Query.new
  end

  shared_examples_for 'logical operator expressions' do

    context '$and operator' do
      context '$and to empty query' do
        let(:modified) do
          query.send(query_method, '$and', [{'foo' => 'bar'}])
        end

        it 'adds to top level' do
          modified.selector.should == {'$and' => [{'foo' => 'bar'}]}
        end
      end

      context '$and to query with other keys' do
        let(:query) do
          Mongoid::Query.new.where(zoom: 'zoom')
        end

        let(:modified) do
          query.send(query_method, '$and', [{'foo' => 'bar'}])
        end

        it 'adds to top level' do
          modified.selector.should == {'zoom' => 'zoom',
            '$and' => [{'foo' => 'bar'}]}
        end
      end

      context '$and to query with $and' do
        let(:query) do
          Mongoid::Query.new.where('$and' => [{zoom: 'zoom'}])
        end

        let(:modified) do
          query.send(query_method, '$and', [{'foo' => 'bar'}])
        end

        it 'adds to existing $and' do
          modified.selector.should == {
            '$and' => [{'zoom' => 'zoom'}, {'foo' => 'bar'}]}
        end
      end

    end

    context '$or operator' do
      context '$or to empty query' do
        let(:modified) do
          query.send(query_method, '$or', [{'foo' => 'bar'}])
        end

        it 'adds to top level' do
          modified.selector.should == {'$or' => [{'foo' => 'bar'}]}
        end
      end

      context '$or to query with other keys' do
        let(:query) do
          Mongoid::Query.new.where(zoom: 'zoom')
        end

        let(:modified) do
          query.send(query_method, '$or', [{'foo' => 'bar'}])
        end

        it 'replaces top level' do
          modified.selector.should == {
            '$or' => [{'zoom' => 'zoom'}, {'foo' => 'bar'}]}
        end
      end

      context '$or to query with $or' do
        let(:query) do
          Mongoid::Query.new.where('$or' => [{zoom: 'zoom'}])
        end

        let(:modified) do
          query.send(query_method, '$or', [{'foo' => 'bar'}])
        end

        it 'adds to existing $or' do
          modified.selector.should == {
            '$or' => [{'zoom' => 'zoom'}, {'foo' => 'bar'}]}
        end
      end

    end
  end

  describe '#add_operator_expression' do
    let(:query_method) { :add_operator_expression }

    it_behaves_like 'logical operator expressions'
  end

  describe '#add_logical_operator_expression' do
    let(:query_method) { :add_logical_operator_expression }

    it_behaves_like 'logical operator expressions'
  end
end
