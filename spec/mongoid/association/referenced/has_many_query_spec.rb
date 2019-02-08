# frozen_string_literal: true

require "spec_helper"
require_relative './has_many_models'

describe Mongoid::Association::Referenced::HasMany do
  context 'when projecting with #only' do
    before do
      school = HmmSchool.create!(district: 'foo')
      HmmStudent.create!(school: school, name: 'Dave', grade: 10)
    end

    let(:school) do
      HmmSchool.where(district: 'foo').only('students._id', 'students.name').first
    end

    let(:student) { school.students.first }

    it 'populates specified fields only' do
      pending 'https://jira.mongodb.org/browse/MONGOID-4704'

      expect(student.name).to eq('Dave')
      # has a default value specified in the model
      expect do
        student.grade
      end.to raise_error(ActiveModel::MissingAttributeError)
      expect(student.attributes.keys).to eq(['_id', 'name'])
    end

    # Delete this test when https://jira.mongodb.org/browse/MONGOID-4704 is
    # implemented and above test is unpended
    it 'fetches all fields' do
      expect(student.name).to eq('Dave')
      expect(student.grade).to eq(10)
    end
  end
end
