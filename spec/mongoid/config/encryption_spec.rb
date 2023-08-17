# frozen_string_literal: true
# rubocop:todo all

require "spec_helper"
require "support/crypt/models"

describe Mongoid::Config::Encryption do

  describe ".encryption_schema_map" do

    let(:encryption_schema_map) do
      Mongoid.config.encryption_schema_map(database_id, models)
    end

    context "when a model has encrypted fields" do
      context 'when model has encrypt_metadata' do
        let(:expected_schema_map) do
          {
            "mongoid_test.crypt_patients" => {
              "bsonType" => "object",
              "encryptMetadata" => {
                "keyId" => [BSON::Binary.new(Base64.decode64("grolrnFVSSW9Gq04Q87R9Q=="), :uuid)]
              },
              "properties" => {
                "medical_records" => {
                  "encrypt" => {
                    "bsonType" => "array",
                    "algorithm" => "AEAD_AES_256_CBC_HMAC_SHA_512-Random"
                  }
                },
                "blood_type" => {
                  "encrypt" => {
                    "keyId" => "/blood_type_key_name",
                    "bsonType" => "string",
                    "algorithm" => "AEAD_AES_256_CBC_HMAC_SHA_512-Random"
                  }
                },
                "ssn" => {
                  "encrypt" => {
                    "bsonType" => "int",
                    "algorithm" => "AEAD_AES_256_CBC_HMAC_SHA_512-Deterministic"
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
              },
            }
          }
        end

        let(:models) do
          [Crypt::Patient]
        end

        it "returns a map of encryption schemas" do
          expect(encryption_schema_map).to eq(expected_schema_map)
        end

        context "when models are related" do
          let(:models) do
            [Crypt::Patient, Crypt::Insurance]
          end

          it "returns a map of encryption schemas" do
            expect(encryption_schema_map).to eq(expected_schema_map)
          end
        end

        context 'and fields do not have encryption options' do
          let(:models) do
            [Crypt::Car]
          end

          let(:expected_schema_map) do
            {
              "vehicles.crypt_cars" => {
                "bsonType" => "object",
                "encryptMetadata" => {
                  "keyId" => [BSON::Binary.new(Base64.decode64("grolrnFVSSW9Gq04Q87R9Q=="), :uuid)],
                  "algorithm" => "AEAD_AES_256_CBC_HMAC_SHA_512-Deterministic"
                },
                "properties" => {
                  "vin" => {
                    "encrypt" => {
                      "bsonType" => "string"
                    }
                  }
                }
              }
            }
          end

          it "returns a map of encryption schemas" do
            expect(encryption_schema_map).to eq(expected_schema_map)
          end
        end
      end

      context 'when model does not have encrypt_metadata' do
        let(:expected_schema_map) do
          {
            "mongoid_test.crypt_users" => {
              "properties" => {
                "name" => {
                  "encrypt" => {
                    'keyId' => [BSON::Binary.new(Base64.decode64("grolrnFVSSW9Gq04Q87R9Q=="), :uuid)],
                    "bsonType" => "string",
                    "algorithm" => "AEAD_AES_256_CBC_HMAC_SHA_512-Random"
                  }
                },
                "email" => {
                  "encrypt" => {
                    'keyId' => [BSON::Binary.new(Base64.decode64("S34mE/HhSFSym3yErpER6Q=="), :uuid)],
                    "bsonType" => "string",
                    "algorithm" => "AEAD_AES_256_CBC_HMAC_SHA_512-Deterministic"
                  }
                }
              }
            }
          }
        end

        let(:models) do
          [Crypt::User]
        end

        it "returns a map of encryption schemas" do
          expect(encryption_schema_map).to eq(expected_schema_map)
        end
      end
    end

    context 'when a model does not have encrypted fields' do
      let(:models) do
        [Person]
      end

      it 'returns an empty map' do
        expect(encryption_schema_map).to eq({})
      end
    end
  end
end
