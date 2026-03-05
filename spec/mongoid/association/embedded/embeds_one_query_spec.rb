# frozen_string_literal: true
# rubocop:todo all

require "spec_helper"
require_relative './embeds_one_models'

describe Mongoid::Association::Embedded::EmbedsOne do

  context 'when projecting with #only' do
    before do
      parent = EomParent.new(name: 'foo')
      parent.child = EomChild.new(a: 1, b: 2)
      parent.save!
    end

    let(:parent) do
      EomParent.where(name: 'foo').only(:name, 'child._id', 'child.a').first
    end

    it 'populates specified fields only' do
      expect(parent.child.a).to eq(1)
      # has a default value specified in the model
      expect do
        parent.child.b
      end.to raise_error(Mongoid::Errors::AttributeNotLoaded, /Attempted to access attribute 'b' on EomChild which was not loaded/)
      expect(parent.child.attributes.keys).to eq(['_id', 'a'])
    end
  end
end
