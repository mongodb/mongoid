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
  end
end
