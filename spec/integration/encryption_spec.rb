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
    Mongoid.default_client[Crypt::Folder.collection_name].drop
    existing_key_id = Crypt::Patient.encrypt_metadata[:key_id]
    Crypt::Patient.set_key_id(data_key_id)
    Crypt::Car.set_key_id(data_key_id)
    Crypt::Note.set_key_id(data_key_id)
    Mongoid::Config.send(:clients=, config)
    Mongoid::Clients.with_name(:key_vault)[key_vault_collection].drop
    Crypt::Patient.store_in(client: :encrypted)
    Crypt::Car.store_in(client: :encrypted, database: Crypt::Car.storage_options[:database])
    Crypt::Folder.store_in(client: :encrypted)

    example.run

    Crypt::Patient.reset_storage_options!
    Crypt::Folder.reset_storage_options!
    Crypt::Patient.set_key_id(existing_key_id)
    Crypt::Car.set_key_id(existing_key_id)
    Crypt::Note.set_key_id(existing_key_id)
  end

  it 'encrypts and decrypts fields' do
    patient = Crypt::Patient.create!(
      code: '12345',
      medical_records: %w[one two three],
      blood_type: 'A+',
      blood_type_key_name: key_alt_name,
      ssn: 123_456_789,
      insurance: Crypt::Insurance.new(policy_number: 123_456_789)
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
      medical_records: %w[one two three],
      blood_type: 'A+',
      blood_type_key_name: key_alt_name,
      ssn: 123_456_789,
      insurance: Crypt::Insurance.new(policy_number: 123_456_789)
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

  # Nothing about the parent document says it needs a schema: it has no
  # encrypted field of its own and no encrypt_with. Its collection still needs
  # one, or the embedded field goes out in the clear.
  it 'stores an embedded field encrypted when the parent has no encrypted field' do
    folder = Crypt::Folder.create!(note: Crypt::Note.new(text: 'SECRET'))
    unencrypted_client[Crypt::Folder.collection.name].find(_id: folder.id).first.tap do |doc|
      expect(doc['note']['text']).to be_a(BSON::Binary)
      expect(doc['note']['text'].type).to eq(:ciphertext)
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

  # The encryption schema map is keyed by namespace and built once, when the
  # client is constructed. Whenever the namespace an encrypted model actually
  # writes to is not in that map, the driver encrypts nothing and reports no
  # error, so the field lands in the clear. Mongoid fails closed instead.
  describe 'when the target namespace is not in the encryption schema map' do
    let(:scratch_databases) do
      %w[vehicles_dynamic vehicles_tenant_b vehicles_tenant_c tenant_a]
    end

    around do |example|
      original_options = {
        Crypt::DynamicCar => Crypt::DynamicCar.storage_options,
        Crypt::TenantCar => Crypt::TenantCar.storage_options
      }
      existing_key_ids = original_options.keys.to_h { |model| [ model, model.encrypt_metadata[:key_id] ] }
      original_options.each_key do |model|
        model.set_key_id(data_key_id)
        model.store_in(client: :encrypted)
      end
      clean_scratch_data
      # The schema map is generated when the client is built, so the client has
      # to be built after the storage options above are in place.
      Mongoid::Clients.clear

      example.run

      clean_scratch_data
      original_options.each { |model, options| model.storage_options = options }
      existing_key_ids.each { |model, key_id| model.set_key_id(key_id) }
      Mongoid::Clients.clear
    end

    def clean_scratch_data
      scratch_databases.each { |database| unencrypted_client.use(database).database.drop }
      # Crypt::Car writes into the shared 'vehicles' database, which other
      # examples rely on, so remove only the documents these examples create.
      unencrypted_client
        .use(Crypt::Car.storage_options[:database])[Crypt::Car.collection_name.to_s]
        .delete_many(vin: { '$in' => %w[CLIENT-1 CLIENT-2] })
    end

    # Reads with a client that has no automatic encryption, to see what really
    # landed on disk.
    def documents_with_plaintext_vin(database, collection, vin)
      unencrypted_client.use(database)[collection].find(vin: vin).to_a
    end

    context 'when the database name is a callable' do
      it 'does not store the field in plaintext', :aggregate_failures do
        expect { Crypt::DynamicCar.create!(vin: 'DYNAMIC-1') }
          .to raise_error(Mongoid::Errors::NoEncryptionSchema)

        expect(
          documents_with_plaintext_vin('vehicles_dynamic', Crypt::DynamicCar.collection_name.to_s, 'DYNAMIC-1')
        ).to be_empty
      end
    end

    context 'when the database name is a callable resolved per tenant' do
      around do |example|
        Thread.current[:tenant_database] = 'tenant_a'
        example.run
        Thread.current[:tenant_database] = nil
      end

      it 'does not store the field in plaintext', :aggregate_failures do
        expect { Crypt::TenantCar.create!(vin: 'TENANT-1') }
          .to raise_error(Mongoid::Errors::NoEncryptionSchema)

        expect(
          documents_with_plaintext_vin('tenant_a', Crypt::TenantCar.collection_name.to_s, 'TENANT-1')
        ).to be_empty
      end
    end

    context 'when the database is overridden for the block' do
      it 'does not store the field in plaintext', :aggregate_failures do
        expect { Crypt::Car.with(database: 'vehicles_tenant_b') { |car| car.create!(vin: 'BLOCK-1') } }
          .to raise_error(Mongoid::Errors::NoEncryptionSchema)

        expect(
          documents_with_plaintext_vin('vehicles_tenant_b', Crypt::Car.collection_name.to_s, 'BLOCK-1')
        ).to be_empty
      end
    end

    context 'when the database is overridden globally' do
      persistence_context_override :database, 'vehicles_tenant_c'

      it 'does not store the field in plaintext', :aggregate_failures do
        expect { Crypt::Car.create!(vin: 'GLOBAL-1') }
          .to raise_error(Mongoid::Errors::NoEncryptionSchema)

        expect(
          documents_with_plaintext_vin('vehicles_tenant_c', Crypt::Car.collection_name.to_s, 'GLOBAL-1')
        ).to be_empty
      end
    end

    context 'when the model is routed to a client without automatic encryption' do
      it 'does not store the field in plaintext', :aggregate_failures do
        expect { Crypt::Car.with(client: :default) { |car| car.create!(vin: 'CLIENT-1') } }
          .to raise_error(Mongoid::Errors::NoEncryptionSchema)

        expect(
          documents_with_plaintext_vin('vehicles', Crypt::Car.collection_name.to_s, 'CLIENT-1')
        ).to be_empty
      end
    end

    context 'when the parent has no encrypted field of its own' do
      it 'does not store the embedded field in plaintext', :aggregate_failures do
        expect { Crypt::Folder.with(client: :default) { |folder| folder.create!(note: Crypt::Note.new(text: 'EMBEDDED-1')) } }
          .to raise_error(Mongoid::Errors::NoEncryptionSchema)

        expect(
          unencrypted_client[Crypt::Folder.collection_name.to_s].find('note.text' => 'EMBEDDED-1').to_a
        ).to be_empty
      end
    end

    context 'when the client is overridden globally to one without automatic encryption' do
      persistence_context_override :client, :default

      it 'does not store the field in plaintext', :aggregate_failures do
        expect { Crypt::Car.create!(vin: 'CLIENT-2') }
          .to raise_error(Mongoid::Errors::NoEncryptionSchema)

        expect(
          documents_with_plaintext_vin('vehicles', Crypt::Car.collection_name.to_s, 'CLIENT-2')
        ).to be_empty
      end
    end
  end
end
