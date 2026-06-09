# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Association::Referenced::HasManyThrough::Eager do
  before(:all) do
    Object.const_set(:EgPhysician, Class.new do
      include Mongoid::Document

      store_in collection: 'eg_physicians'
      has_many :eg_appointments, class_name: 'EgAppointment', inverse_of: :eg_physician
      has_many :eg_patients, through: :eg_appointments,
                             class_name: 'EgPatient', source: :eg_patient
    end)
    Object.const_set(:EgAppointment, Class.new do
      include Mongoid::Document

      store_in collection: 'eg_appointments'
      belongs_to :eg_physician, class_name: 'EgPhysician'
      belongs_to :eg_patient, class_name: 'EgPatient'
    end)
    Object.const_set(:EgPatient, Class.new do
      include Mongoid::Document

      store_in collection: 'eg_patients'
    end)
  end

  after(:all) do
    %w[EgPhysician EgAppointment EgPatient].each { |c| Object.send(:remove_const, c) }
  end

  before { [ EgPhysician, EgAppointment, EgPatient ].each(&:delete_all) }

  it 'preloads patients for multiple physicians' do
    p1 = EgPhysician.create!
    p2 = EgPhysician.create!
    pat1 = EgPatient.create!
    pat2 = EgPatient.create!
    pat3 = EgPatient.create!
    EgAppointment.create!(eg_physician: p1, eg_patient: pat1)
    EgAppointment.create!(eg_physician: p1, eg_patient: pat2)
    EgAppointment.create!(eg_physician: p2, eg_patient: pat3)

    physicians = EgPhysician.includes(:eg_patients).to_a
    by_id = physicians.index_by(&:id)

    expect(by_id[p1.id].eg_patients.to_a).to contain_exactly(pat1, pat2)
    expect(by_id[p2.id].eg_patients.to_a).to contain_exactly(pat3)
  end

  it 'sets [] on physicians with no appointments' do
    lone = EgPhysician.create!
    physicians = EgPhysician.includes(:eg_patients).to_a
    loaded = physicians.find { |p| p.id == lone.id }
    expect(loaded.eg_patients.to_a).to eq([])
  end
end
