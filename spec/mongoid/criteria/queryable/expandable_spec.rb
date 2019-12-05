# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Criteria::Queryable::Expandable do

  let(:query) do
    Mongoid::Query.new
  end

  describe '#expand_condition' do

    let(:expanded) do
      query.send(:expand_condition, condition)
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

=begin
    context 'operator => operator value expression' do
      shared_examples_for 'expands' do

        it 'expands' do
          expanded.should == {'foo' => 'bar'}
        end
      end

      context 'string key' do
        let(:condition) do
          {'$in' => %w(bar)}
        end

        it_behaves_like 'expands'
      end

      context 'symbol key' do
        let(:condition) do
          {:$in => %w(bar)}
        end

        it_behaves_like 'expands'
      end
    end
=end
  end
end
