# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Association::EagerLoadable do
  context 'with through associations' do
    before(:all) do
      Object.const_set(:ELPhysician, Class.new do
        include Mongoid::Document

        store_in collection: 'el_physicians'
        has_many :el_appointments, class_name: 'ELAppointment', inverse_of: :el_physician
        has_many :el_patients, through: :el_appointments,
                               class_name: 'ELPatient', source: :el_patient
      end)
      Object.const_set(:ELAppointment, Class.new do
        include Mongoid::Document

        store_in collection: 'el_appointments'
        belongs_to :el_physician, class_name: 'ELPhysician'
        belongs_to :el_patient, class_name: 'ELPatient'
      end)
      Object.const_set(:ELPatient, Class.new do
        include Mongoid::Document

        store_in collection: 'el_patients'
      end)
    end

    after(:all) do
      %w[ELPhysician ELAppointment ELPatient].each { |c| Object.send(:remove_const, c) }
    end

    before { [ ELPhysician, ELAppointment, ELPatient ].each(&:delete_all) }

    it 'logs a warning and falls back to preload when eager_load is used with a through association' do
      physician = ELPhysician.create!
      patient   = ELPatient.create!
      ELAppointment.create!(el_physician: physician, el_patient: patient)

      expect(Mongoid.logger).to receive(:warn).with(a_string_including('through'))

      docs = ELPhysician.eager_load(:el_patients).to_a
      expect(docs.first.el_patients.to_a).to include(patient)
    end
  end
end
