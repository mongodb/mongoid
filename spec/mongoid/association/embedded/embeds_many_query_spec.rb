# frozen_string_literal: true

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

    context 'when using only with $' do
      before do
        Patient.destroy_all
        Patient.create!(
          title: 'Steve',
          addresses: [
            Address.new(number: '123'),
            Address.new(number: '456'),
          ],
        )
      end

      let(:patient) do
        Patient.where('addresses.number' => {'$gt' => 100}).only('addresses.$').first
      end

      it 'loads embedded association' do
        expect(patient.addresses.first.number).to eq(123)
      end
    end

    context "when excluding the relation" do
      let(:congress) do
        EmmCongress.where(name: 'foo').only(:_id).first
      end

      it 'raises a MissingAttributeError' do
        expect do
          congress.legislators
        end.to raise_error(ActiveModel::MissingAttributeError)
      end
    end
  end
end
