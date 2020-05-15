# frozen_string_literal: true
# encoding: utf-8

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
      query.send(:_mongoid_expand_keys, {a: 1}).should == {a: 1}
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

    it 'expands simple and Key instances on the same field' do
      query.send(:_mongoid_expand_keys, {'age' => 42, lt => 50}).should == {
        'age' => {'$eq' => 42, '$lt' => 50}}
    end

    it 'expands Key and simple instances on the same field' do
      query.send(:_mongoid_expand_keys, {gt => 42, 'age' => 50}).should == {
        'age' => {'$gt' => 42, '$eq' => 50}}
    end

    it 'Ruby does not allow same symbol operator with different values' do
      {gt => 42, gtp => 50}.should == {gtp => 50}
    end
  end
end
