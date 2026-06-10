# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Association::Referenced::HasManyThrough::Proxy do
  before(:all) do
    Object.const_set(:PxAppointment, Class.new do
      include Mongoid::Document

      field :physician_id, type: BSON::ObjectId
      field :patient_id,   type: BSON::ObjectId
      belongs_to :px_physician, class_name: 'PxPhysician'
      belongs_to :px_patient, class_name: 'PxPatient'
    end)
    Object.const_set(:PxPatient, Class.new { include Mongoid::Document })
    Object.const_set(:PxPhysician, Class.new do
      include Mongoid::Document

      has_many :px_appointments, class_name: 'PxAppointment', inverse_of: :px_physician
      has_many :px_patients, through: :px_appointments, class_name: 'PxPatient',
                             source: :px_patient
    end)
  end

  after(:all) do
    %w[PxPhysician PxAppointment PxPatient].each { |c| Object.send(:remove_const, c) }
  end

  let(:physician) { PxPhysician.new }

  describe 'mutation methods' do
    %i[<< push concat build create create! delete delete_all
       destroy_all clear nullify substitute].each do |method|
      it "raises ReadonlyAssociation on ##{method}" do
        expect { physician.px_patients.public_send(method) }.to \
          raise_error(Mongoid::Errors::ReadonlyAssociation)
      end
    end
  end

  describe 'read methods' do
    it 'responds to #each' do
      expect(physician.px_patients).to respond_to(:each)
    end

    it 'responds to #to_a' do
      expect(physician.px_patients).to respond_to(:to_a)
    end

    it 'responds to #count' do
      expect(physician.px_patients).to respond_to(:count)
    end
  end

  describe '.eager_loader' do
    it 'returns a HasManyThrough::Eager' do
      assoc = PxPhysician.relations['px_patients']
      result = described_class.eager_loader([ assoc ], [])
      expect(result).to be_a(Mongoid::Association::Referenced::HasManyThrough::Eager)
    end
  end
end
