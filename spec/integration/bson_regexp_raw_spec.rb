# frozen_string_literal: true
# encoding: utf-8

require 'spec_helper'

describe BSON::Regexp::Raw do
  context 'fully qualified name' do
    it 'can be created' do
      regexp = BSON::Regexp::Raw.new('foo')
      regexp.pattern.should == 'foo'
    end
  end

  context 'via ::Regexp' do
    it 'can be created' do
      regexp = Regexp::Raw.new('foo')
      regexp.pattern.should == 'foo'
    end
  end
end
