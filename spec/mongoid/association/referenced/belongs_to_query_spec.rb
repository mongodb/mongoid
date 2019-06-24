# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"
require_relative './has_many_models'

describe Mongoid::Association::Referenced::BelongsTo do
  context 'when projecting with #only' do
    before do
      school = HmmSchool.create!(district: 'foo', team: 'Bulldogs')
      HmmStudent.create!(school: school, name: 'Dave', grade: 10)
    end

    let(:student) do
      HmmStudent.where(name: 'Dave').only(:school_id, 'school._id', 'school.district').first
    end

    let(:school) { student.school }

    it 'populates specified fields only' do
      pending 'https://jira.mongodb.org/browse/MONGOID-4704'

      expect(school.district).to eq('foo')
      # has a default value specified in the model
      expect do
        school.team
      end.to raise_error(ActiveModel::MissingAttributeError)
      expect(student.attributes.keys).to eq(['_id', 'name'])
    end

    # Delete this test when https://jira.mongodb.org/browse/MONGOID-4704 is
    # implemented and above test is unpended
    it 'fetches all fields' do
      expect(school.district).to eq('foo')
      expect(school.team).to eq('Bulldogs')
    end
  end
end
