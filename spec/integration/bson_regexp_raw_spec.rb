# frozen_string_literal: true

require 'spec_helper'

describe BSON::Regexp::Raw do
  context 'fully qualified name' do
    it 'can be created' do
      regexp = BSON::Regexp::Raw.new('foo')
      expect(regexp.pattern).to eq('foo')
    end
  end

  context 'via ::Regexp' do
    it 'can be created' do
      regexp = Regexp::Raw.new('foo')
      expect(regexp.pattern).to eq('foo')
    end
  end
end
