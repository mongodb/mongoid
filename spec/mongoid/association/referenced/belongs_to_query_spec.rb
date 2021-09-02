# frozen_string_literal: true

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

  context 'when projecting with #only while having similar inverse_of candidates' do
    before do
      alice = HmmOwner.create!(name: 'Alice')
      bob = HmmOwner.create!(name: 'Bob')

      HmmPet.create!(name: 'Rex', current_owner: bob, previous_owner: alice)
    end

    let(:pet) { HmmPet.where(name: 'Rex').only(:name, :previous_owner_id, 'previous_owner.name').first }

    it 'populates specified fields' do
      expect(pet.name).to eq('Rex')
      expect(pet.previous_owner.name).to eq('Alice')
    end

    it 'does not try to load the inverse for an association that explicitly prevents it' do
      expect { pet.previous_owner.name }.not_to raise_error
    end
  end
end
