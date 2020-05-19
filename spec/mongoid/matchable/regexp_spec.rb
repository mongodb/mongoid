# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Matchable::Regexp do

  let(:matcher) do
    described_class.new(attribute)
  end

  let(:attribute) do
    'Emily'
  end

  describe '#_matches?' do

    context 'when a BSON::Regexp::Raw object is passed' do

      let(:regexp) do
        BSON::Regexp::Raw.new("\\AEm")
      end

      it 'compiles the regexp object to a native regexp for the matching' do
        expect(matcher._matches?(regexp)).to be(true)
      end

      context 'when the value does not match the attribute' do

        let(:attribute) do
          'ily'
        end

        it 'compiles the regexp object to a native regexp for the matching' do
          expect(matcher._matches?(regexp)).to be(false)
        end
      end
    end

    context 'when a native Regexp object is passed' do

      let(:regexp) do
        /\AEm/
      end

      it 'calls super with the native regexp' do
        expect(matcher._matches?(regexp)).to be(true)
      end

      context 'when the value does not match the attribute' do

        let(:attribute) do
          'ily'
        end

        it 'compiles the regexp object to a native regexp for the matching' do
          expect(matcher._matches?(regexp)).to be(false)
        end
      end
    end
  end
end
