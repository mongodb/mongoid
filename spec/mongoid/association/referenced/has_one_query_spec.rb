# frozen_string_literal: true

require "spec_helper"
require_relative './has_one_models'

describe Mongoid::Association::Referenced::HasOne do
  context 'when projecting with #only' do
    before do
      college = HomCollege.create!(state: 'ny')
      HomAccreditation.create!(college: college, degree: 'cs', year: 2017)
    end

    let(:college) do
      HomCollege.where(state: 'ny').only('accreditation._id', 'accreditation.degree').first
    end

    let(:accreditation) { college.accreditation }

    it 'populates specified fields only' do
      pending 'https://jira.mongodb.org/browse/MONGOID-4704'

      expect(accreditation.degree).to eq('cs')
      # has a default value specified in the model
      expect do
        accreditation.year
      end.to raise_error(ActiveModel::MissingAttributeError)
      expect(legislator.attributes.keys).to eq(['_id', 'degree'])
    end

    # Delete this test when https://jira.mongodb.org/browse/MONGOID-4704 is
    # implemented and above test is unpended
    it 'fetches all fields' do
      expect(accreditation.degree).to eq('cs')
      expect(accreditation.year).to eq(2017)
    end
  end
end
