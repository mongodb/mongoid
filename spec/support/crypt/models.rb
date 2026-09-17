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

  # An encrypted model whose database name is a callable resolving to a
  # constant. The callable form of :database is supported by store_in, but the
  # encryption schema map is keyed by namespace and built once, so this model's
  # namespace is not known when the map is generated.
  class DynamicCar
    include Mongoid::Document

    store_in database: -> { 'vehicles_dynamic' }

    encrypt_with key_id: 'grolrnFVSSW9Gq04Q87R9Q==', deterministic: true

    field :vin, type: String, encrypt: true
  end

  # An encrypted model using the documented multi-tenant idiom, where the
  # database name is only known once a tenant is selected. There is no correct
  # value to resolve at client construction time.
  class TenantCar
    include Mongoid::Document

    # The fallback keeps this model usable by tasks that iterate every model,
    # such as Mongoid::Tasks::Database.create_collections. Mongoid raises
    # NoMethodError when a callable :database resolves to nil.
    store_in database: -> { Thread.current[:tenant_database] || 'vehicles_no_tenant' }

    encrypt_with key_id: 'grolrnFVSSW9Gq04Q87R9Q==', deterministic: true

    field :vin, type: String, encrypt: true
  end

  # An encrypted model that is embedded by more than one parent, and more than
  # once by the same parent.
  class Token
    include Mongoid::Document

    field :value, type: String, encrypt: { deterministic: true }

    embedded_in :tokenized, polymorphic: true
  end

  # A parent whose encrypted data lives entirely in an embedded model: it has
  # no encrypted field of its own and no encrypt_with.
  class Wallet
    include Mongoid::Document

    embeds_one :token, class_name: 'Crypt::Token', as: :tokenized
  end

  # Two parents embedding the same encrypted model.
  class Vault
    include Mongoid::Document

    encrypt_with key_id: 'grolrnFVSSW9Gq04Q87R9Q=='

    embeds_one :token, class_name: 'Crypt::Token', as: :tokenized
  end

  class Chest
    include Mongoid::Document

    encrypt_with key_id: 'grolrnFVSSW9Gq04Q87R9Q=='

    embeds_one :token, class_name: 'Crypt::Token', as: :tokenized
  end

  # A parent embedding the same encrypted model through two relations.
  class Ledger
    include Mongoid::Document

    encrypt_with key_id: 'grolrnFVSSW9Gq04Q87R9Q=='

    embeds_one :primary_token, class_name: 'Crypt::Token', as: :tokenized
    embeds_one :backup_token, class_name: 'Crypt::Token', as: :tokenized
  end

  # Three levels of nesting, where the middle level has no encrypted field of
  # its own.
  class Owner
    include Mongoid::Document

    encrypt_with key_id: 'grolrnFVSSW9Gq04Q87R9Q=='

    embeds_one :account, class_name: 'Crypt::Account'
  end

  class Account
    include Mongoid::Document

    embedded_in :owner, class_name: 'Crypt::Owner'
    embeds_one :credential, class_name: 'Crypt::Credential'
  end

  class Credential
    include Mongoid::Document

    field :secret, type: String, encrypt: { deterministic: true }

    embedded_in :account, class_name: 'Crypt::Account'
  end

  # A model that embeds itself. The walk over embedded relations has to stop
  # here, or generating the map never terminates.
  class Comment
    include Mongoid::Document

    field :body, type: String, encrypt: { deterministic: true }

    embedded_in :commentable, polymorphic: true
    embeds_one :reply, class_name: 'Crypt::Comment', as: :commentable
  end

  class Article
    include Mongoid::Document

    encrypt_with key_id: 'grolrnFVSSW9Gq04Q87R9Q=='

    embeds_one :comment, class_name: 'Crypt::Comment', as: :commentable
  end

  # A parent with no encrypted field of its own: the encrypted field lives on
  # the embedded model. Used by the integration specs, so the embedded model
  # carries a key id.
  class Folder
    include Mongoid::Document

    embeds_one :note, class_name: 'Crypt::Note'
  end

  class Note
    include Mongoid::Document

    encrypt_with key_id: 'grolrnFVSSW9Gq04Q87R9Q==', deterministic: true

    field :text, type: String, encrypt: true

    embedded_in :folder, class_name: 'Crypt::Folder'
  end

  # A model naming an embedded class that is never defined. The association
  # cannot be used, so nothing is ever embedded through it, but every model in
  # the application is walked when the schema map is generated.
  class Drawer
    include Mongoid::Document

    embeds_one :missing_note, class_name: 'Crypt::MissingNote'
  end

  # The same, on a model that is encrypted itself, so the walk descends into
  # its relations.
  class Cabinet
    include Mongoid::Document

    field :label, type: String, encrypt: { deterministic: true }

    embeds_one :missing_note, class_name: 'Crypt::MissingNote'
  end
end
