# frozen_string_literal: true

require 'spec_helper'
require 'support/crypt/models'

describe Mongoid::Config::Encryption do
  describe '.encryption_schema_map' do
    let(:encryption_schema_map) do
      Mongoid.config.encryption_schema_map(database_id, models)
    end

    context 'when a model has encrypted fields' do
      context 'when model has encrypt_metadata' do
        let(:expected_schema_map) do
          {
            'mongoid_test.crypt_patients' => {
              'bsonType' => 'object',
              'encryptMetadata' => {
                'keyId' => [ BSON::Binary.new(Base64.decode64('grolrnFVSSW9Gq04Q87R9Q=='), :uuid) ]
              },
              'properties' => {
                'medical_records' => {
                  'encrypt' => {
                    'bsonType' => 'array',
                    'algorithm' => 'AEAD_AES_256_CBC_HMAC_SHA_512-Random'
                  }
                },
                'blood_type' => {
                  'encrypt' => {
                    'keyId' => '/blood_type_key_name',
                    'bsonType' => 'string',
                    'algorithm' => 'AEAD_AES_256_CBC_HMAC_SHA_512-Random'
                  }
                },
                'ssn' => {
                  'encrypt' => {
                    'bsonType' => 'int',
                    'algorithm' => 'AEAD_AES_256_CBC_HMAC_SHA_512-Deterministic'
                  }
                },
                'insurance' => {
                  'bsonType' => 'object',
                  'properties' => {
                    'policy_number' => {
                      'encrypt' => {
                        'bsonType' => 'int',
                        'algorithm' => 'AEAD_AES_256_CBC_HMAC_SHA_512-Deterministic'
                      }
                    }
                  }
                }
              }
            }
          }
        end

        let(:models) do
          [ Crypt::Patient ]
        end

        it 'returns a map of encryption schemas' do
          expect(encryption_schema_map).to eq(expected_schema_map)
        end

        context 'when models are related' do
          let(:models) do
            [ Crypt::Patient, Crypt::Insurance ]
          end

          it 'returns a map of encryption schemas' do
            expect(encryption_schema_map).to eq(expected_schema_map)
          end
        end

        # Models are registered in class load order, and Rails eager loads
        # app/models alphabetically, so a child whose file name sorts before
        # its parent's arrives first.
        context 'when the embedded model comes before its parent' do
          let(:models) do
            [ Crypt::Insurance, Crypt::Patient ]
          end

          it 'returns a map of encryption schemas' do
            expect(encryption_schema_map).to eq(expected_schema_map)
          end
        end

        context 'and fields do not have encryption options' do
          let(:models) do
            [ Crypt::Car ]
          end

          let(:expected_schema_map) do
            {
              'vehicles.crypt_cars' => {
                'bsonType' => 'object',
                'encryptMetadata' => {
                  'keyId' => [ BSON::Binary.new(Base64.decode64('grolrnFVSSW9Gq04Q87R9Q=='), :uuid) ],
                  'algorithm' => 'AEAD_AES_256_CBC_HMAC_SHA_512-Deterministic'
                },
                'properties' => {
                  'vin' => {
                    'encrypt' => {
                      'bsonType' => 'string'
                    }
                  }
                }
              }
            }
          end

          it 'returns a map of encryption schemas' do
            expect(encryption_schema_map).to eq(expected_schema_map)
          end
        end
      end

      context 'when model does not have encrypt_metadata' do
        let(:expected_schema_map) do
          {
            'mongoid_test.crypt_users' => {
              'bsonType' => 'object',
              'properties' => {
                'name' => {
                  'encrypt' => {
                    'keyId' => [ BSON::Binary.new(Base64.decode64('grolrnFVSSW9Gq04Q87R9Q=='), :uuid) ],
                    'bsonType' => 'string',
                    'algorithm' => 'AEAD_AES_256_CBC_HMAC_SHA_512-Random'
                  }
                },
                'email' => {
                  'encrypt' => {
                    'keyId' => [ BSON::Binary.new(Base64.decode64('S34mE/HhSFSym3yErpER6Q=='), :uuid) ],
                    'bsonType' => 'string',
                    'algorithm' => 'AEAD_AES_256_CBC_HMAC_SHA_512-Deterministic'
                  }
                }
              }
            }
          }
        end

        let(:models) do
          [ Crypt::User ]
        end

        it 'returns a map of encryption schemas' do
          expect(encryption_schema_map).to eq(expected_schema_map)
        end
      end
    end

    context 'when a model does not have encrypted fields' do
      let(:models) do
        [ Person ]
      end

      it 'returns an empty map' do
        expect(encryption_schema_map).to eq({})
      end
    end

    # A belongs_to association generates an Object field for its foreign key.
    # When the field was declared with a type of its own, that declared type
    # has to reach the schema: it is what libmongocrypt checks the value
    # against before encrypting it.
    context 'when an encrypted field is a belongs_to foreign key' do
      let(:defined_models) { [] }

      let(:encryption_options) { { deterministic: true } }

      let(:models) do
        owner = Class.new do
          include Mongoid::Document

          store_in collection: 'crypt_encrypted_foreign_key_owners'
        end
        defined_models << owner
        stub_const('Crypt::EncryptedForeignKeyOwner', owner)

        reference = Class.new do
          include Mongoid::Document

          store_in collection: 'crypt_encrypted_foreign_key_references'
        end
        defined_models << reference
        stub_const('Crypt::EncryptedForeignKeyReference', reference)
        reference.field(:owner_id, type: BSON::ObjectId, encrypt: encryption_options)
        reference.belongs_to(:owner, class_name: 'Crypt::EncryptedForeignKeyOwner', inverse_of: nil)

        [ reference ]
      end

      after do
        defined_models.each { |model| Mongoid.deregister_model(model) }
      end

      it 'uses the declared type of the foreign key' do
        expect(encryption_schema_map['mongoid_test.crypt_encrypted_foreign_key_references']).to eq(
          'bsonType' => 'object',
          'properties' => {
            'owner_id' => {
              'encrypt' => {
                'bsonType' => 'objectId',
                'algorithm' => 'AEAD_AES_256_CBC_HMAC_SHA_512-Deterministic'
              }
            }
          }
        )
      end

      context 'when the field specifies a key alt name' do
        let(:encryption_options) { { deterministic: false, key_name_field: :owner_key_name } }

        it 'keeps the key alt name of the field' do
          expect(
            encryption_schema_map.dig(
              'mongoid_test.crypt_encrypted_foreign_key_references',
              'properties', 'owner_id', 'encrypt'
            )
          ).to eq(
            'keyId' => '/owner_key_name',
            'bsonType' => 'objectId',
            'algorithm' => 'AEAD_AES_256_CBC_HMAC_SHA_512-Random'
          )
        end
      end
    end

    # A parent and its subclass write to one collection. When each declares the
    # belongs_to foreign key with its own encryption options, the declaration of
    # the subclass must not be replaced by the association declared on the
    # parent: the schema merge reports the disagreement instead.
    context 'when a belongs_to foreign key is encrypted differently on a parent and a subclass' do
      let(:defined_models) { [] }

      let(:parent_key_id) { 'grolrnFVSSW9Gq04Q87R9Q==' }

      let(:child_key_id) { 'S34mE/HhSFSym3yErpER6Q==' }

      let(:parent_options) { { deterministic: true, key_id: parent_key_id } }

      let(:child_options) { { deterministic: false, key_id: child_key_id } }

      let(:parent) do
        klass = Class.new do
          include Mongoid::Document

          store_in collection: 'crypt_inherited_foreign_keys'
        end
        defined_models << klass
        stub_const('Crypt::SchemaInheritedParent', klass)
        klass
      end

      let(:child) do
        parent
        klass = Class.new(parent)
        defined_models << klass
        stub_const('Crypt::SchemaInheritedChild', klass)
        klass
      end

      let(:models) do
        [ parent, child ]
      end

      before do
        parent.field(:owner_id, type: BSON::ObjectId, encrypt: parent_options)
        child.field(:owner_id, type: BSON::ObjectId, encrypt: child_options)
        parent.belongs_to(:owner, class_name: 'Person', inverse_of: nil)
      end

      after do
        defined_models.each { |model| Mongoid.deregister_model(model) }
      end

      it 'keeps the options of each field' do
        parent_field = parent.fields['owner_id']
        child_field = child.fields['owner_id']

        expect(parent_field).to be_a(Mongoid::Fields::EncryptedForeignKey)
        expect(parent_field.type).to eq(BSON::ObjectId)
        expect(parent_field.deterministic?).to be true
        expect(parent_field.key_id).to eq(parent_key_id)

        expect(child_field).to be_a(Mongoid::Fields::EncryptedForeignKey)
        expect(child_field.type).to eq(BSON::ObjectId)
        expect(child_field.deterministic?).to be false
        expect(child_field.key_id).to eq(child_key_id)
      end

      it 'raises for the shared collection' do
        expect { encryption_schema_map }.to raise_error(Mongoid::Errors::InvalidEncryptionSchema)
      end

      context 'when both fields use the same encryption options' do
        let(:child_options) { parent_options }

        it 'keeps the shared options on both fields' do
          expect(parent.fields['owner_id'].deterministic?).to be true
          expect(parent.fields['owner_id'].key_id).to eq(parent_key_id)
          expect(child.fields['owner_id'].deterministic?).to be true
          expect(child.fields['owner_id'].key_id).to eq(parent_key_id)
        end

        it 'builds the schema for the shared collection' do
          expect(
            encryption_schema_map.dig('mongoid_test.crypt_inherited_foreign_keys', 'properties', 'owner_id')
          ).to eq(
            'encrypt' => {
              'bsonType' => 'objectId',
              'algorithm' => 'AEAD_AES_256_CBC_HMAC_SHA_512-Deterministic',
              'keyId' => [ BSON::Binary.new(Base64.decode64(parent_key_id), :uuid) ]
            }
          )
        end
      end
    end

    # A field left out of the schema map is written in plaintext, with no
    # exception and nothing logged, so an omission here is silent data
    # exposure rather than a broken feature.
    context 'when the encrypted fields are on an embedded model' do
      let(:token_properties) do
        {
          'bsonType' => 'object',
          'properties' => {
            'value' => {
              'encrypt' => {
                'bsonType' => 'string',
                'algorithm' => 'AEAD_AES_256_CBC_HMAC_SHA_512-Deterministic'
              }
            }
          }
        }
      end

      context 'when two models embed the same encrypted model' do
        let(:models) do
          [ Crypt::Vault, Crypt::Chest ]
        end

        it 'maps the embedded model for the first parent' do
          expect(encryption_schema_map.dig('mongoid_test.crypt_vaults', 'properties', 'token'))
            .to eq(token_properties)
        end

        it 'maps the embedded model for the second parent' do
          expect(encryption_schema_map.dig('mongoid_test.crypt_chests', 'properties', 'token'))
            .to eq(token_properties)
        end
      end

      context 'when one model embeds the same encrypted model twice' do
        let(:models) do
          [ Crypt::Ledger ]
        end

        it 'maps the first relation' do
          expect(encryption_schema_map.dig('mongoid_test.crypt_ledgers', 'properties', 'primary_token'))
            .to eq(token_properties)
        end

        it 'maps the second relation' do
          expect(encryption_schema_map.dig('mongoid_test.crypt_ledgers', 'properties', 'backup_token'))
            .to eq(token_properties)
        end
      end

      # relation_class constantizes, and a polymorphic embedded_in has no class
      # to resolve, so the walk has to look at the relation type first.
      context 'when the embedded model is embedded polymorphically' do
        let(:models) do
          [ Crypt::Vault ]
        end

        it 'does not raise' do
          expect { encryption_schema_map }.not_to raise_error
        end
      end

      context 'when the embedded model comes before its parent' do
        let(:models) do
          [ Crypt::Token, Crypt::Vault ]
        end

        it 'maps the embedded model' do
          expect(encryption_schema_map.dig('mongoid_test.crypt_vaults', 'properties', 'token'))
            .to eq(token_properties)
        end
      end

      context 'when the parent has no encrypted field of its own' do
        let(:models) do
          [ Crypt::Wallet, Crypt::Token ]
        end

        it 'maps the embedded model' do
          expect(encryption_schema_map.dig('mongoid_test.crypt_wallets', 'properties', 'token'))
            .to eq(token_properties)
        end
      end

      context 'when the encrypted model is nested three levels deep' do
        let(:account_properties) do
          {
            'bsonType' => 'object',
            'properties' => {
              'credential' => {
                'bsonType' => 'object',
                'properties' => {
                  'secret' => {
                    'encrypt' => {
                      'bsonType' => 'string',
                      'algorithm' => 'AEAD_AES_256_CBC_HMAC_SHA_512-Deterministic'
                    }
                  }
                }
              }
            }
          }
        end

        context 'when the models are listed outermost first' do
          let(:models) do
            [ Crypt::Owner, Crypt::Account, Crypt::Credential ]
          end

          it 'maps the whole subtree' do
            expect(encryption_schema_map.dig('mongoid_test.crypt_owners', 'properties', 'account'))
              .to eq(account_properties)
          end
        end

        context 'when the middle model comes first' do
          let(:models) do
            [ Crypt::Account, Crypt::Owner, Crypt::Credential ]
          end

          it 'maps the whole subtree' do
            expect(encryption_schema_map.dig('mongoid_test.crypt_owners', 'properties', 'account'))
              .to eq(account_properties)
          end
        end
      end

      # The document is persisted under the store_as key, so that is the key
      # libmongocrypt has to find. Keyed by the association name, the fields
      # would be written in plaintext.
      context 'when the association uses store_as' do
        let(:token_properties) do
          {
            'bsonType' => 'object',
            'properties' => {
              'token' => {
                'encrypt' => {
                  'bsonType' => 'string',
                  'algorithm' => 'AEAD_AES_256_CBC_HMAC_SHA_512-Deterministic'
                }
              }
            }
          }
        end

        let(:models) do
          [ Crypt::Dossier, Crypt::DossierSecret ]
        end

        let(:properties) do
          encryption_schema_map.dig('mongoid_test.crypt_dossiers', 'properties')
        end

        it 'keys the nested schema by the stored name' do
          expect(properties.keys).to eq([ 's' ])
          expect(properties['s']).to eq(token_properties)
        end

        it 'reports the stored name as the encrypted path' do
          expect(Mongoid.config.encrypted_paths_for(Crypt::Dossier)).to eq([ %w[s token] ])
        end
      end

      context 'when a nested association uses store_as' do
        let(:token_properties) do
          {
            'bsonType' => 'object',
            'properties' => {
              'token' => {
                'encrypt' => {
                  'bsonType' => 'string',
                  'algorithm' => 'AEAD_AES_256_CBC_HMAC_SHA_512-Deterministic'
                }
              }
            }
          }
        end

        let(:models) do
          [ Crypt::Archive, Crypt::ArchiveEntry, Crypt::ArchivePayload ]
        end

        it 'keys every level by its stored name' do
          expect(encryption_schema_map.dig('mongoid_test.crypt_archives', 'properties')).to eq(
            'e' => {
              'bsonType' => 'object',
              'properties' => { 'p' => token_properties }
            }
          )
        end

        it 'reports the stored names as the encrypted path' do
          expect(Mongoid.config.encrypted_paths_for(Crypt::Archive)).to eq([ %w[e p token] ])
        end
      end

      # The walk has to keep stopping at a model it is already inside of,
      # otherwise a self-embedding model recurses forever.
      context 'when a model embeds itself' do
        let(:models) do
          [ Crypt::Article ]
        end

        it 'terminates' do
          expect { encryption_schema_map }.not_to raise_error
        end

        it 'maps the embedded model without descending into the cycle' do
          expect(encryption_schema_map.dig('mongoid_test.crypt_articles', 'properties', 'comment')).to eq(
            'bsonType' => 'object',
            'properties' => {
              'body' => {
                'encrypt' => {
                  'bsonType' => 'string',
                  'algorithm' => 'AEAD_AES_256_CBC_HMAC_SHA_512-Deterministic'
                }
              }
            }
          )
        end
      end
    end

    context 'when an encrypted model has a callable database name' do
      let(:models) do
        [ Crypt::DynamicCar ]
      end

      it 'does not build a key from the unresolved callable' do
        expect(encryption_schema_map.keys.grep(/Proc/)).to be_empty
      end

      it 'does not build a key that the model can never write to' do
        expect(encryption_schema_map.keys).to all(satisfy { |key| key.count('.') == 1 })
      end
    end

    context 'when an encrypted model has a callable database name that needs a tenant' do
      let(:models) do
        [ Crypt::TenantCar ]
      end

      # Resolving the callable while the map is built is not a fix: the
      # documented multi-tenant idiom has no correct value at client
      # construction time. Generating the map must not depend on it.
      it 'does not raise' do
        expect { encryption_schema_map }.not_to raise_error
      end

      it 'does not pin the map to whichever tenant happens to be current' do
        Thread.current[:tenant_database] = 'tenant_a'
        expect(encryption_schema_map.keys).not_to include('tenant_a.crypt_tenant_cars')
      ensure
        Thread.current[:tenant_database] = nil
      end
    end

    # The map is generated over every model in the application, and a model may
    # name an embedded class that is never defined. Resolving that name raises,
    # which would take down every client build.
    context 'when a model names an embedded class that is not defined' do
      let(:models) do
        [ Crypt::Drawer, Crypt::Cabinet ]
      end

      it 'does not raise' do
        expect { encryption_schema_map }.not_to raise_error
      end

      it 'leaves out the model with nothing to encrypt' do
        expect(encryption_schema_map.keys).not_to include('mongoid_test.crypt_drawers')
      end

      it 'still maps the encrypted fields of the model itself' do
        expect(encryption_schema_map.dig('mongoid_test.crypt_cabinets', 'properties', 'label')).to eq(
          'encrypt' => {
            'bsonType' => 'string',
            'algorithm' => 'AEAD_AES_256_CBC_HMAC_SHA_512-Deterministic'
          }
        )
      end
    end

    # The map has one entry per namespace. Every model that writes to the
    # namespace, including subclasses that are never registered in
    # Mongoid.models, has to be covered by that entry, or its encrypted fields
    # are written in plaintext.
    context 'when more than one model writes to a namespace' do
      let(:encrypt_metadata) do
        {
          'keyId' => [ BSON::Binary.new(Base64.decode64('grolrnFVSSW9Gq04Q87R9Q=='), :uuid) ],
          'algorithm' => 'AEAD_AES_256_CBC_HMAC_SHA_512-Deterministic'
        }
      end

      let(:encrypted_string) do
        { 'encrypt' => { 'bsonType' => 'string' } }
      end

      context 'when two models are stored in one collection' do
        let(:expected_entry) do
          {
            'bsonType' => 'object',
            'encryptMetadata' => encrypt_metadata,
            'properties' => {
              'serial' => encrypted_string,
              'holder' => encrypted_string
            }
          }
        end

        context 'when the models are registered in one order' do
          let(:models) do
            [ Crypt::Badge, Crypt::BadgeScan ]
          end

          it 'maps the fields of both models' do
            expect(encryption_schema_map['mongoid_test.crypt_badges']).to eq(expected_entry)
          end
        end

        context 'when the models are registered in the other order' do
          let(:models) do
            [ Crypt::BadgeScan, Crypt::Badge ]
          end

          it 'maps the fields of both models' do
            expect(encryption_schema_map['mongoid_test.crypt_badges']).to eq(expected_entry)
          end
        end
      end

      context 'when a subclass adds an encrypted field to an encrypted parent' do
        let(:expected_entry) do
          {
            'bsonType' => 'object',
            'encryptMetadata' => encrypt_metadata,
            'properties' => {
              'ssn' => encrypted_string,
              'salary' => encrypted_string,
              'rate' => encrypted_string
            }
          }
        end

        # Subclasses are not registered in Mongoid.models, so only the parent
        # is passed in.
        context 'when only the parent is registered' do
          let(:models) do
            [ Crypt::Member ]
          end

          it 'maps the fields of the parent and of every subclass' do
            expect(encryption_schema_map['mongoid_test.crypt_members']).to eq(expected_entry)
          end
        end

        context 'when a subclass is registered as well' do
          let(:models) do
            [ Crypt::Member, Crypt::Employee ]
          end

          it 'maps the fields of the parent and of every subclass' do
            expect(encryption_schema_map['mongoid_test.crypt_members']).to eq(expected_entry)
          end
        end
      end

      context 'when only a subclass has encrypted fields' do
        let(:models) do
          [ Crypt::Listing ]
        end

        it 'maps the fields of the subclass' do
          expect(encryption_schema_map['mongoid_test.crypt_listings']).to eq(
            'bsonType' => 'object',
            'encryptMetadata' => encrypt_metadata,
            'properties' => {
              'owner_ssn' => encrypted_string
            }
          )
        end
      end

      context 'when a subclass of an embeds_one target adds an encrypted field' do
        let(:models) do
          [ Crypt::Box ]
        end

        it 'maps the fields of the target and of its subclass' do
          expect(encryption_schema_map.dig('mongoid_test.crypt_boxes', 'properties', 'item')).to eq(
            'bsonType' => 'object',
            'properties' => {
              'label' => encrypted_string,
              'seal' => encrypted_string
            }
          )
        end
      end

      context 'when only a subclass of an embeds_one target has encrypted fields' do
        let(:models) do
          [ Crypt::Locker ]
        end

        it 'maps the fields of the subclass' do
          expect(encryption_schema_map.dig('mongoid_test.crypt_lockers', 'properties', 'content')).to eq(
            'bsonType' => 'object',
            'encryptMetadata' => encrypt_metadata,
            'properties' => {
              'code' => encrypted_string
            }
          )
        end
      end

      # These models are not added to the shared support file: every client
      # with automatic encryption builds the map over all registered models,
      # and a conflict would make every such client fail to build.
      context 'when models on one collection disagree on encryption' do
        let(:defined_models) { [] }

        after do
          defined_models.each { |model| Mongoid.deregister_model(model) }
        end

        def define_model(&block)
          model = Class.new do
            include Mongoid::Document

            store_in collection: 'crypt_conflicts'
          end
          model.class_eval(&block)
          defined_models << model
          model
        end

        context 'when the same field is encrypted the same way' do
          let(:models) do
            [
              define_model { field :code, type: String, encrypt: { deterministic: true } },
              define_model { field :code, type: String, encrypt: { deterministic: true } }
            ]
          end

          it 'maps the field once' do
            expect(encryption_schema_map['mongoid_test.crypt_conflicts']).to eq(
              'bsonType' => 'object',
              'properties' => {
                'code' => {
                  'encrypt' => {
                    'bsonType' => 'string',
                    'algorithm' => 'AEAD_AES_256_CBC_HMAC_SHA_512-Deterministic'
                  }
                }
              }
            )
          end
        end

        context 'when the same field is encrypted differently' do
          let(:models) do
            [
              define_model { field :code, type: String, encrypt: { deterministic: true } },
              define_model { field :code, type: String, encrypt: { deterministic: false } }
            ]
          end

          it 'raises' do
            expect { encryption_schema_map }.to raise_error(Mongoid::Errors::InvalidEncryptionSchema)
          end
        end

        context 'when the collection metadata differs' do
          let(:models) do
            [
              define_model do
                encrypt_with key_id: 'grolrnFVSSW9Gq04Q87R9Q==', deterministic: true
                field :code, type: String, encrypt: true
              end,
              define_model do
                encrypt_with key_id: 'grolrnFVSSW9Gq04Q87R9Q==', deterministic: false
                field :name, type: String, encrypt: true
              end
            ]
          end

          it 'raises' do
            expect { encryption_schema_map }.to raise_error(Mongoid::Errors::InvalidEncryptionSchema)
          end
        end

        context 'when a subclass encrypts an inherited field differently' do
          let(:models) do
            parent = define_model { field :code, type: String, encrypt: { deterministic: true } }
            Class.new(parent) { field :code, type: String, encrypt: { deterministic: false } }
            [ parent ]
          end

          it 'raises' do
            expect { encryption_schema_map }.to raise_error(Mongoid::Errors::InvalidEncryptionSchema)
          end
        end
      end
    end
  end
end
