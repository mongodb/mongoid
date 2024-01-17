# rubocop:todo all
module Crypt
  class Patient
    include Mongoid::Document

    encrypt_with key_id: "grolrnFVSSW9Gq04Q87R9Q=="

    field :code, type: String
    field :medical_records, type: Array, encrypt: { deterministic: false}
    field :blood_type, type: String, encrypt: {
      deterministic: false,
      key_name_field: :blood_type_key_name
    }
    field :ssn, type: Integer, encrypt: { deterministic: true }
    field :blood_type_key_name, type: String

    embeds_one :insurance, class_name: "Crypt::Insurance"
  end

  class Insurance
    include Mongoid::Document

    field :policy_number, type: Integer, encrypt: { deterministic: true }
    embedded_in :patient, class_name: "Crypt::Patient"
  end

  class User
    include Mongoid::Document

    field :name, type: String, encrypt: {
      key_id: "grolrnFVSSW9Gq04Q87R9Q==",
      deterministic: false
    }
    field :email, type: String, encrypt: {
      key_id: "S34mE/HhSFSym3yErpER6Q==",
      deterministic: true
    }
  end

  class Car
    include Mongoid::Document

    store_in database: 'vehicles'

    encrypt_with key_id: "grolrnFVSSW9Gq04Q87R9Q==", deterministic: true

    field :vin, type: String, encrypt: true
    field :make, type: String
  end
end
