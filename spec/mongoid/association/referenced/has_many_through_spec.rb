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

  context 'integration — belongs_to source (join table)', :integration do
    before(:all) do
      Object.const_set(:JtPhysician, Class.new do
        include Mongoid::Document

        store_in collection: 'jt_physicians'
        has_many :jt_appointments, class_name: 'JtAppointment', inverse_of: :jt_physician
        has_many :jt_patients, through: :jt_appointments,
                               class_name: 'JtPatient', source: :jt_patient
      end)
      Object.const_set(:JtAppointment, Class.new do
        include Mongoid::Document

        store_in collection: 'jt_appointments'
        belongs_to :jt_physician, class_name: 'JtPhysician'
        belongs_to :jt_patient, class_name: 'JtPatient'
      end)
      Object.const_set(:JtPatient, Class.new do
        include Mongoid::Document

        store_in collection: 'jt_patients'
      end)
    end

    after(:all) do
      %w[JtPhysician JtAppointment JtPatient].each { |c| Object.send(:remove_const, c) }
    end

    before { [ JtPhysician, JtAppointment, JtPatient ].each(&:delete_all) }

    let!(:physician) { JtPhysician.create! }
    let!(:patient1)  { JtPatient.create! }
    let!(:patient2)  { JtPatient.create! }
    let!(:_appt1)    { JtAppointment.create!(jt_physician: physician, jt_patient: patient1) }
    let!(:_appt2)    { JtAppointment.create!(jt_physician: physician, jt_patient: patient2) }

    it 'returns all patients through appointments' do
      expect(physician.jt_patients.to_a).to contain_exactly(patient1, patient2)
    end

    it 'does not include patients of other physicians' do
      other = JtPhysician.create!
      other_patient = JtPatient.create!
      JtAppointment.create!(jt_physician: other, jt_patient: other_patient)
      expect(physician.jt_patients.to_a).not_to include(other_patient)
    end

    it 'returns an empty result when no appointments exist' do
      lone = JtPhysician.create!
      expect(lone.jt_patients.to_a).to eq([])
    end

    it 'reloads on demand' do
      physician.jt_patients.to_a # prime cache
      new_patient = JtPatient.create!
      JtAppointment.create!(jt_physician: physician, jt_patient: new_patient)
      expect(physician.jt_patients(true).to_a).to include(new_patient)
    end

    it 'raises ReadonlyAssociation on <<' do
      expect { physician.jt_patients << JtPatient.new }.to \
        raise_error(Mongoid::Errors::ReadonlyAssociation)
    end

    it 'exposes a singular_ids getter' do
      ids = physician.jt_patient_ids
      expect(ids).to contain_exactly(patient1.id, patient2.id)
    end
  end

  context 'integration — has_many source', :integration do
    before(:all) do
      Object.const_set(:HmAuthor, Class.new do
        include Mongoid::Document

        store_in collection: 'hm_authors'
        has_many :hm_books, class_name: 'HmBook', inverse_of: :hm_author
        has_many :hm_readers, through: :hm_books,
                              class_name: 'HmReader', source: :hm_readers
      end)
      Object.const_set(:HmBook, Class.new do
        include Mongoid::Document

        store_in collection: 'hm_books'
        belongs_to :hm_author, class_name: 'HmAuthor'
        has_many :hm_readers, class_name: 'HmReader', inverse_of: :hm_book
      end)
      Object.const_set(:HmReader, Class.new do
        include Mongoid::Document

        store_in collection: 'hm_readers'
        belongs_to :hm_book, class_name: 'HmBook'
      end)
    end

    after(:all) do
      %w[HmAuthor HmBook HmReader].each { |c| Object.send(:remove_const, c) }
    end

    before { [ HmAuthor, HmBook, HmReader ].each(&:delete_all) }

    let!(:author) { HmAuthor.create! }
    let!(:book1)  { HmBook.create!(hm_author: author) }
    let!(:book2)  { HmBook.create!(hm_author: author) }
    let!(:r1)     { HmReader.create!(hm_book: book1) }
    let!(:r2)     { HmReader.create!(hm_book: book1) }
    let!(:r3)     { HmReader.create!(hm_book: book2) }

    it 'returns readers across all books' do
      expect(author.hm_readers.to_a).to contain_exactly(r1, r2, r3)
    end
  end
end
