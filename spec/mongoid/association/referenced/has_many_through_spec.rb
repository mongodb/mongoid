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

    context 'when the source association is has_and_belongs_to_many' do
      before(:all) do
        Object.const_set(:HabtmTag, Class.new { include Mongoid::Document })
        Object.const_set(:HabtmPost, Class.new do
          include Mongoid::Document

          has_and_belongs_to_many :habtm_tags, class_name: 'HabtmTag'
        end)
        Object.const_set(:HabtmBlog, Class.new do
          include Mongoid::Document

          has_many :habtm_posts, class_name: 'HabtmPost', inverse_of: :habtm_blog
          has_many :habtm_tags, through: :habtm_posts, class_name: 'HabtmTag'
        end)
      end

      after(:all) do
        %w[HabtmBlog HabtmPost HabtmTag].each { |c| Object.send(:remove_const, c) }
      end

      it 'raises InvalidRelationOption' do
        blog_assoc = HabtmBlog.relations['habtm_tags']
        expect { blog_assoc.source_association }.to \
          raise_error(Mongoid::Errors::InvalidRelationOption)
      end
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

    it 'accepts :order' do
      expect do
        Physician.has_many(:ordered_patients, through: :appointments,
                                              class_name: 'Patient', source: :patient,
                                              order: { _id: 1 })
      end.not_to raise_error
    end
  end

  describe '#criteria' do
    it 'returns a scoped Criteria for the source class' do
      physician = Physician.new
      appointments_crit = instance_double(Mongoid::Criteria, pluck: [])
      allow(assoc.through_association).to receive(:criteria).with(physician).and_return(appointments_crit)
      crit = assoc.criteria(physician)
      expect(crit).to be_a(Mongoid::Criteria)
      expect(crit.klass).to eq(Patient)
    end
  end

  context 'integration - belongs_to source (join table)', :integration do
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

  context 'integration - has_many source', :integration do
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

  context 'integration - :order option', :integration do
    before(:all) do
      Object.const_set(:OrdPhysician, Class.new do
        include Mongoid::Document

        store_in collection: 'ord_physicians'
        has_many :ord_appointments, class_name: 'OrdAppointment', inverse_of: :ord_physician
        has_many :ord_patients, through: :ord_appointments,
                                class_name: 'OrdPatient', source: :ord_patient,
                                order: { name: 1 }
      end)
      Object.const_set(:OrdAppointment, Class.new do
        include Mongoid::Document

        store_in collection: 'ord_appointments'
        belongs_to :ord_physician, class_name: 'OrdPhysician'
        belongs_to :ord_patient,   class_name: 'OrdPatient'
      end)
      Object.const_set(:OrdPatient, Class.new do
        include Mongoid::Document

        store_in collection: 'ord_patients'
        field :name, type: String
      end)
    end

    after(:all) do
      %w[OrdPhysician OrdAppointment OrdPatient].each { |c| Object.send(:remove_const, c) }
    end

    before { [ OrdPhysician, OrdAppointment, OrdPatient ].each(&:delete_all) }

    it 'returns patients in the declared order' do
      physician = OrdPhysician.create!
      charlie   = OrdPatient.create!(name: 'Charlie')
      alice     = OrdPatient.create!(name: 'Alice')
      bob       = OrdPatient.create!(name: 'Bob')
      [ charlie, alice, bob ].each do |p|
        OrdAppointment.create!(ord_physician: physician, ord_patient: p)
      end
      expect(physician.ord_patients.to_a).to eq([ alice, bob, charlie ])
    end
  end
end
