# frozen_string_literal: true

require 'spec_helper'

describe 'Encrypted has_and_belongs_to_many foreign keys' do
  let(:model) do
    klass = stub_const('ForeignKeyHabtmMember', Class.new)
    klass.include(Mongoid::Document)
    klass
  end

  after do
    Mongoid.deregister_model(model)
  end

  [ true, { deterministic: true }, { deterministic: false } ].each do |encryption|
    context "with encrypt: #{encryption.inspect}" do
      it 'rejects the association when its foreign key is already encrypted' do
        model.field(:secret_group_ids, type: Array, encrypt: encryption)

        expect do
          model.has_and_belongs_to_many(:groups, foreign_key: :secret_group_ids, inverse_of: nil)
        end.to raise_error(Mongoid::Errors::InvalidEncryptedAssociation, /encrypt/i)
      end

      it 'rejects encryption when the foreign key already belongs to an association' do
        model.has_and_belongs_to_many(:groups, inverse_of: nil)

        expect do
          model.field(:group_ids, type: Array, encrypt: encryption)
        end.to raise_error(Mongoid::Errors::InvalidEncryptedAssociation, /encrypt/i)
      end
    end
  end

  it 'allows an unencrypted foreign key' do
    model.field(:group_ids, type: Array)

    expect do
      model.has_and_belongs_to_many(:groups, inverse_of: nil)
    end.not_to raise_error
  end

  context 'when the encrypted field is declared on a parent model' do
    let(:parent_model) do
      klass = stub_const('ForeignKeyHabtmParent', Class.new)
      klass.include(Mongoid::Document)
      klass
    end

    let(:custom_foreign_key) { nil }

    let(:foreign_key) { custom_foreign_key || :group_ids }

    let(:association_options) do
      { inverse_of: nil }.tap do |options|
        options[:foreign_key] = custom_foreign_key if custom_foreign_key
      end
    end

    let(:child_model) do
      parent_model
      klass = stub_const('ForeignKeyHabtmChild', Class.new(parent_model))
      klass.has_and_belongs_to_many(:groups, association_options)
      klass
    end

    after do
      Mongoid.deregister_model(child_model)
      Mongoid.deregister_model(parent_model)
    end

    encryption_options = [ { deterministic: true }, { deterministic: false } ]
    custom_foreign_keys = [ nil, :secret_group_ids ]
    encryption_options.each do |encryption|
      custom_foreign_keys.each do |custom_key|
        key_type = custom_key ? 'a custom' : 'the default'
        context "with #{encryption.inspect} and #{key_type} foreign key" do
          let(:custom_foreign_key) { custom_key }

          it 'rejects the field before changing either model' do
            association = child_model.relations['groups']
            existing_field = child_model.fields[foreign_key.to_s]

            expect do
              parent_model.field(foreign_key, type: Array, encrypt: encryption)
            end.to raise_error(Mongoid::Errors::InvalidEncryptedAssociation, /encrypt/i)

            expect(parent_model.fields).not_to have_key(foreign_key.to_s)
            expect(child_model.fields[foreign_key.to_s]).to equal(existing_field)
            expect(child_model.fields[foreign_key.to_s]).not_to be_encrypted
            expect(child_model.relations['groups']).to equal(association)
          end
        end
      end
    end

    it 'allows an encrypted field that no descendant uses as an association key' do
      child_model

      expect do
        parent_model.field(:secret, type: String, encrypt: { deterministic: true })
      end.not_to raise_error

      expect(parent_model.fields['secret']).to be_encrypted
      expect(child_model.fields['secret']).to be_encrypted
    end
  end

  context 'when the encrypted field is declared on a child model' do
    let(:parent_model) do
      klass = stub_const('ForeignKeyHabtmParentWithChildField', Class.new)
      klass.include(Mongoid::Document)
      klass
    end

    let(:child_model) do
      parent_model
      klass = stub_const('ForeignKeyHabtmChildWithField', Class.new(parent_model))
      klass.field(:group_ids, type: Array, encrypt: { deterministic: false })
      klass
    end

    after do
      Mongoid.deregister_model(child_model)
      Mongoid.deregister_model(parent_model)
    end

    it 'rejects the association before changing either model' do
      existing_field = child_model.fields['group_ids']

      expect do
        parent_model.has_and_belongs_to_many(:groups, inverse_of: nil)
      end.to raise_error(Mongoid::Errors::InvalidEncryptedAssociation, /encrypt/i)

      expect(parent_model.fields).not_to have_key('group_ids')
      expect(parent_model.relations).not_to have_key('groups')
      expect(child_model.fields['group_ids']).to equal(existing_field)
      expect(child_model.fields['group_ids']).to be_encrypted
    end
  end
end
