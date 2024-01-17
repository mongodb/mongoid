# rubocop:todo all
require 'spec_helper'
require 'support/crypt/models'

describe 'Encryption' do
  require_enterprise
  require_libmongocrypt
  include_context 'with encryption'
  restore_config_clients

  let(:config) do
    {
      default: { hosts: SpecConfig.instance.addresses, database: database_id },
      key_vault: { hosts: SpecConfig.instance.addresses, database: :key_vault },
      encrypted: {
        hosts: SpecConfig.instance.addresses,
        database: database_id,
        options: {
          auto_encryption_options: {
            key_vault_client: :key_vault,
            kms_providers: kms_providers,
            key_vault_namespace: key_vault_namespace,
            extra_options: extra_options
          }
        }
      }
    }
  end

  let(:unencrypted_client) do
    Mongoid.default_client
  end

  around do |example|
    Mongoid.default_client[Crypt::Patient.collection_name].drop
    Mongoid.default_client[Crypt::Car.collection_name].drop
    existing_key_id = Crypt::Patient.encrypt_metadata[:key_id]
    Crypt::Patient.set_key_id(data_key_id)
    Crypt::Car.set_key_id(data_key_id)
    Mongoid::Config.send(:clients=, config)
    Mongoid::Clients.with_name(:key_vault)[key_vault_collection].drop
    Crypt::Patient.store_in(client: :encrypted)
    Crypt::Car.store_in(client: :encrypted, database: Crypt::Car.storage_options[:database])

    example.run

    Crypt::Patient.reset_storage_options!
    Crypt::Patient.set_key_id(existing_key_id)
    Crypt::Car.set_key_id(existing_key_id)
  end

  it 'encrypts and decrypts fields' do
    patient = Crypt::Patient.create!(
      code: '12345',
      medical_records: ['one', 'two', 'three'],
      blood_type: 'A+',
      blood_type_key_name: key_alt_name,
      ssn: 123456789,
      insurance: Crypt::Insurance.new(policy_number: 123456789)
    )
    Crypt::Patient.find(patient.id).tap do |found_patient|
      expect(found_patient.code).to eq(patient.code)
      expect(found_patient.medical_records).to eq(patient.medical_records)
      expect(found_patient.blood_type).to eq(patient.blood_type)
      expect(found_patient.ssn).to eq(patient.ssn)
      expect(found_patient.insurance.policy_number).to eq(patient.insurance.policy_number)
    end
  end

  it 'stores data encrypted in the database' do
    patient = Crypt::Patient.create!(
      code: '12345',
      medical_records: ['one', 'two', 'three'],
      blood_type: 'A+',
      blood_type_key_name: key_alt_name,
      ssn: 123456789,
      insurance: Crypt::Insurance.new(policy_number: 123456789)
    )
    unencrypted_client[Crypt::Patient.collection.name].find(_id: patient.id).first.tap do |doc|
      %w[medical_records blood_type ssn].each do |field|
        expect(doc[field]).to be_a(BSON::Binary)
        expect(doc[field].type).to eq(:ciphertext)
      end
      expect(doc['insurance']['policy_number']).to be_a(BSON::Binary)
      expect(doc['code']).to eq('12345')
    end
  end

  it 'stores data encrypted in the non-default database' do
    car = Crypt::Car.create!(vin: 'VA1234')
    unencrypted_client
      .use(Crypt::Car.storage_options[:database])[Crypt::Car.collection.name]
      .find(_id: car.id).first.tap do |doc|
        expect(doc[:vin]).to be_a(BSON::Binary)
        expect(doc[:vin].type).to eq(:ciphertext)
    end
  end


end
