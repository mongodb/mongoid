# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Criteria::Queryable::Mergeable do

  let(:query) do
    Mongoid::Query.new
  end

  describe "#intersect" do

    before do
      query.intersect
    end

    it "sets the strategy to intersect" do
      expect(query.strategy).to eq(:__intersect__)
    end
  end

  describe "#override" do

    before do
      query.override
    end

    it "sets the strategy to override" do
      expect(query.strategy).to eq(:__override__)
    end
  end

  describe "#union" do

    before do
      query.union
    end

    it "sets the strategy to union" do
      expect(query.strategy).to eq(:__union__)
    end
  end

  describe '#_mongoid_expand_keys' do
    it 'expands simple keys' do
      query.send(:_mongoid_expand_keys, {a: 1}).should == {'a' => 1}
    end

    let(:gt) do
      Mongoid::Criteria::Queryable::Key.new("age", :__override__, "$gt")
    end

    let(:gtp) do
      Mongoid::Criteria::Queryable::Key.new("age", :__override__, "$gt")
    end

    let(:lt) do
      Mongoid::Criteria::Queryable::Key.new("age", :__override__, "$lt")
    end

    it 'expands Key instances' do
      query.send(:_mongoid_expand_keys, {gt => 42}).should == {'age' => {'$gt' => 42}}
    end

    it 'expands multiple Key instances on the same field' do
      query.send(:_mongoid_expand_keys, {gt => 42, lt => 50}).should == {
        'age' => {'$gt' => 42, '$lt' => 50}}
    end

    context 'given implicit equality and Key instance on the same field' do
      [42, 'infinite', [nil]].each do |value|
        context "for non-regular expression value #{value}" do
          context 'implicit equality then Key instance' do
            it 'expands implicit equality with $eq and combines with Key operator' do
              query.send(:_mongoid_expand_keys, {'age' => value, lt => 50}).should == {
                'age' => {'$eq' => value, '$lt' => 50}}
            end
          end

          context 'symbol operator then implicit equality' do
            it 'expands implicit equality with $eq and combines with Key operator' do
              query.send(:_mongoid_expand_keys, {gt => 42, 'age' => value}).should == {
                'age' => {'$gt' => 42, '$eq' => value}}
            end
          end
        end
      end
    end

    context 'given implicit equality with Regexp argument and Key instance on the same field' do
      [/42/, BSON::Regexp::Raw.new('42')].each do |value|
        context "for regular expression value #{value}" do
          context 'implicit equality then Key instance' do
            it 'expands implicit equality with $eq and combines with Key operator' do
              query.send(:_mongoid_expand_keys, {'age' => value, lt => 50}).should == {
                'age' => {'$regex' => value, '$lt' => 50}}
            end
          end

          context 'Key instance then implicit equality' do
            it 'expands implicit equality with $eq and combines with Key operator' do
              query.send(:_mongoid_expand_keys, {gt => 50, 'age' => value}).should == {
                'age' => {'$gt' => 50, '$regex' => value}}
            end
          end
        end
      end
    end

    it 'Ruby does not allow same symbol operator with different values' do
      {gt => 42, gtp => 50}.should == {gtp => 50}
    end

    let(:expanded) do
      query.send(:_mongoid_expand_keys, condition)
    end

    context 'field name => value' do
      shared_examples_for 'expands' do

        it 'expands' do
          expanded.should == {'foo' => 'bar'}
        end
      end

      context 'string key' do
        let(:condition) do
          {'foo' => 'bar'}
        end

        it_behaves_like 'expands'
      end

      context 'symbol key' do
        let(:condition) do
          {foo: 'bar'}
        end

        it_behaves_like 'expands'
      end
    end

    context 'Key instance => value' do
      let(:key) do
        Mongoid::Criteria::Queryable::Key.new(:foo, :__override__, '$gt')
      end

      let(:condition) do
        {key => 'bar'}
      end

      it 'expands' do
        expanded.should == {'foo' => {'$gt' => 'bar'}}
      end
    end

    context 'operator => operator value expression' do
      shared_examples_for 'expands' do

        it 'expands' do
          expanded.should == {'foo' => {'$in' => ['bar']}}
        end
      end

      context 'string key' do
        let(:condition) do
          {foo: {'$in' => %w(bar)}}
        end

        it_behaves_like 'expands'
      end

      context 'symbol key' do
        let(:condition) do
          {foo: {:$in => %w(bar)}}
        end

        it_behaves_like 'expands'
      end
    end
  end
end
