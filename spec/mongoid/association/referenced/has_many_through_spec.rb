# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Association::Referenced::HasManyThrough do
  before(:all) do
    Object.const_set(:Appointment, Class.new do
      include Mongoid::Document

      field :physician_id, type: BSON::ObjectId
      field :patient_id,   type: BSON::ObjectId
      belongs_to :physician
      belongs_to :patient
    end)

    Object.const_set(:Patient, Class.new do
      include Mongoid::Document
    end)

    Object.const_set(:Physician, Class.new do
      include Mongoid::Document

      has_many :appointments
      has_many :patients, through: :appointments
    end)
  end

  after(:all) do
    %w[Physician Appointment Patient].each { |c| Object.send(:remove_const, c) }
  end

  let(:assoc) { Physician.relations['patients'] }

  describe '#through_association' do
    it 'returns the appointments metadata' do
      expect(assoc.through_association).to eq(Physician.relations['appointments'])
    end
  end

  describe '#source_association' do
    it 'returns the patient belongs_to on Appointment' do
      expect(assoc.source_association).to eq(Appointment.relations['patient'])
    end
  end

  describe '#embedded?' do
    it 'returns false' do
      expect(assoc.embedded?).to be false
    end
  end

  describe 'VALID_OPTIONS' do
    it 'rejects unknown options' do
      expect do
        Physician.has_many(:foos, through: :appointments, bad_opt: true)
      end.to raise_error(Mongoid::Errors::InvalidRelationOption)
    end
  end

  describe '#criteria' do
    it 'returns an unscoped Criteria for the source class' do
      crit = assoc.criteria
      expect(crit).to be_a(Mongoid::Criteria)
      expect(crit.klass).to eq(Patient)
    end
  end
end
