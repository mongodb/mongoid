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

  # The schema map has one entry per namespace, and it has to cover every model
  # that writes there: models sharing a collection, subclasses, and subclasses
  # of embedded models. Documents are read back through a client without
  # automatic encryption, to see what is actually stored.
  describe 'when more than one model writes to a namespace' do
    let(:root_models) do
      [ Crypt::Badge, Crypt::BadgeScan, Crypt::Member, Crypt::Listing, Crypt::Box, Crypt::Locker ]
    end

    let(:keyed_models) do
      [ Crypt::Badge, Crypt::BadgeScan, Crypt::Member, Crypt::PrivateListing, Crypt::Box, Crypt::SecretContent ]
    end

    around do |example|
      original_options = root_models.to_h { |model| [ model, model.storage_options ] }
      existing_key_ids = keyed_models.to_h { |model| [ model, model.encrypt_metadata[:key_id] ] }
      keyed_models.each { |model| model.set_key_id(data_key_id) }
      root_models.each do |model|
        unencrypted_client[model.collection_name.to_s].drop
        model.store_in(client: :encrypted)
      end
      # The schema map is generated when the client is built, so the client has
      # to be built after the key ids above are in place.
      Mongoid::Clients.clear

      example.run

      original_options.each { |model, options| model.storage_options = options }
      existing_key_ids.each { |model, key_id| model.set_key_id(key_id) }
      Mongoid::Clients.clear
    end

    def stored_document(model, id)
      unencrypted_client[model.collection_name.to_s].find(_id: id).first
    end

    def expect_ciphertext(value)
      expect(value).to be_a(BSON::Binary).and(have_attributes(type: :ciphertext))
    end

    context 'when two models are stored in one collection' do
      it 'stores the fields of both models encrypted', :aggregate_failures do
        badge = Crypt::Badge.create!(serial: 'SERIAL-1')
        scan = Crypt::BadgeScan.create!(holder: 'HOLDER-1')

        expect_ciphertext(stored_document(Crypt::Badge, badge.id)['serial'])
        expect_ciphertext(stored_document(Crypt::BadgeScan, scan.id)['holder'])
      end
    end

    context 'when a subclass adds an encrypted field to an encrypted parent' do
      it 'stores the fields of the parent and of the subclass encrypted', :aggregate_failures do
        employee = Crypt::Employee.create!(ssn: 'SSN-1', salary: 'SALARY-1')

        stored_document(Crypt::Member, employee.id).tap do |doc|
          expect_ciphertext(doc['ssn'])
          expect_ciphertext(doc['salary'])
        end
      end

      it 'stores the fields of a sibling subclass encrypted' do
        contractor = Crypt::Contractor.create!(ssn: 'SSN-2', rate: 'RATE-1')

        expect_ciphertext(stored_document(Crypt::Member, contractor.id)['rate'])
      end

      it 'reads the fields back' do
        employee = Crypt::Employee.create!(ssn: 'SSN-3', salary: 'SALARY-3')

        expect(Crypt::Member.find(employee.id).salary).to eq('SALARY-3')
      end
    end

    context 'when only a subclass has encrypted fields' do
      it 'stores the fields of the subclass encrypted' do
        listing = Crypt::PrivateListing.create!(title: 'TITLE-1', owner_ssn: 'SSN-4')

        expect_ciphertext(stored_document(Crypt::Listing, listing.id)['owner_ssn'])
      end
    end

    context 'when a subclass of an embeds_one target adds an encrypted field' do
      it 'stores the fields of the target and of the subclass encrypted', :aggregate_failures do
        box = Crypt::Box.create!(item: Crypt::SealedItem.new(label: 'LABEL-1', seal: 'SEAL-1'))

        stored_document(Crypt::Box, box.id)['item'].tap do |item|
          expect_ciphertext(item['label'])
          expect_ciphertext(item['seal'])
        end
      end
    end

    context 'when only a subclass of an embeds_one target has encrypted fields' do
      it 'stores the fields of the subclass encrypted' do
        locker = Crypt::Locker.create!(content: Crypt::SecretContent.new(label: 'LABEL-2', code: 'CODE-1'))

        expect_ciphertext(stored_document(Crypt::Locker, locker.id)['content']['code'])
      end
    end

    # An entry for the namespace exists, but it does not cover every encrypted
    # field of the model. The driver encrypts what the entry lists and writes
    # the rest in plaintext.
    context 'when the schema entry for the namespace misses an encrypted field' do
      let(:config) do
        super().merge(
          partial: {
            hosts: SpecConfig.instance.addresses,
            database: database_id,
            options: {
              auto_encryption_options: {
                key_vault_client: :key_vault,
                kms_providers: kms_providers,
                key_vault_namespace: key_vault_namespace,
                extra_options: extra_options,
                schema_map: partial_schema_map
              }
            }
          }
        )
      end

      let(:partial_schema_map) do
        {
          "#{database_id}.#{Crypt::Member.collection_name}" => {
            'bsonType' => 'object',
            'encryptMetadata' => {
              'keyId' => [ BSON::Binary.new(Base64.decode64(data_key_id), :uuid) ],
              'algorithm' => 'AEAD_AES_256_CBC_HMAC_SHA_512-Deterministic'
            },
            'properties' => {
              'ssn' => { 'encrypt' => { 'bsonType' => 'string' } }
            }
          }
        }
      end

      it 'does not store the field in plaintext', :aggregate_failures do
        expect do
          Crypt::Employee.with(client: :partial) { |klass| klass.create!(ssn: 'SSN-5', salary: 'PARTIAL-1') }
        end.to raise_error(Mongoid::Errors::NoEncryptionSchema)

        expect(
          unencrypted_client[Crypt::Member.collection_name.to_s].find(salary: 'PARTIAL-1').to_a
        ).to be_empty
      end
    end
  end
end
