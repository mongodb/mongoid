# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"
require_relative './embeds_many_models'

describe Mongoid::Association::Embedded::EmbedsMany do

  context 'when projecting with #only' do
    before do
      congress = EmmCongress.new(name: 'foo')
      congress.legislators << EmmLegislator.new(a: 1, b: 2)
      congress.save!
    end

    let(:congress) do
      EmmCongress.where(name: 'foo').only(:name, 'legislators._id', 'legislators.a').first
    end

    let(:legislator) { congress.legislators.first }

    it 'populates specified fields only' do
      expect(legislator.a).to eq(1)
      # has a default value specified in the model
      expect do
        legislator.b
      end.to raise_error(ActiveModel::MissingAttributeError)
      expect(legislator.attributes.keys).to eq(['_id', 'a'])
    end
  end
end
