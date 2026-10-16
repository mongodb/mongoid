# frozen_string_literal: true

require 'spec_helper'
require 'support/crypt/models'

describe Mongoid::Encryptable do
  describe '.requires_encryption_schema?' do
    context 'when the model declares encrypt_with' do
      it 'returns true' do
        expect(Crypt::Vault.requires_encryption_schema?).to be true
      end
    end

    context 'when the model has an encrypted field' do
      it 'returns true' do
        expect(Crypt::User.requires_encryption_schema?).to be true
      end
    end

    context 'when the model embeds an encrypted model' do
      it 'returns true' do
        expect(Crypt::Wallet.requires_encryption_schema?).to be true
      end
    end

    context 'when the encrypted model is nested three levels deep' do
      it 'returns true' do
        expect(Crypt::Owner.requires_encryption_schema?).to be true
      end
    end

    context 'when the model declares no encryption anywhere' do
      it 'returns false' do
        expect(Person.requires_encryption_schema?).to be false
      end
    end

    # An association target does not have to be a Mongoid document. Truck
    # embeds a plain Ruby class.
    context 'when an embedded association target is not a document' do
      it 'returns false' do
        expect(Truck.requires_encryption_schema?).to be false
      end
    end

    context 'when the model embeds itself' do
      it 'terminates' do
        expect(Crypt::Comment.requires_encryption_schema?).to be true
      end
    end

    # Every model is asked this question, including ones naming an embedded
    # class that is never defined. Such an association cannot be used, so
    # nothing is embedded through it and nothing needs encrypting.
    context 'when an embedded association names a class that is not defined' do
      it 'returns false' do
        expect(Crypt::Drawer.requires_encryption_schema?).to be false
      end
    end

    context 'when every embedded association resolves' do
      it 'memoizes a false answer' do
        expect(Truck.requires_encryption_schema?).to be false
        expect(Truck.instance_variable_defined?(:@requires_encryption_schema)).to be true
      end
    end

    context 'when an embedded association does not resolve' do
      it 'does not memoize a false answer' do
        expect(Crypt::Drawer.requires_encryption_schema?).to be false
        expect(Crypt::Drawer.instance_variable_defined?(:@requires_encryption_schema)).to be false
      end
    end

    context 'when an embedded encrypted class is defined after the first check' do
      after do
        if Crypt.const_defined?(:MissingNote, false)
          Mongoid.deregister_model(Crypt::MissingNote)
          Crypt.send(:remove_const, :MissingNote)
        end
        # While the class above existed, resolving it through the association
        # memoized the class on the association, and a true answer on the
        # model. Drop both, so the other examples see the model as it was
        # before the class was defined.
        relation = Crypt::Drawer.relations['missing_note']
        relation.remove_instance_variable(:@klass) if relation.instance_variable_defined?(:@klass)
        if Crypt::Drawer.instance_variable_defined?(:@requires_encryption_schema)
          Crypt::Drawer.remove_instance_variable(:@requires_encryption_schema)
        end
      end

      it 'returns true once the class is loaded' do
        expect(Crypt::Drawer.requires_encryption_schema?).to be false

        missing_note = Class.new do
          include Mongoid::Document

          embedded_in :drawer, class_name: 'Crypt::Drawer'
          field :text, type: String, encrypt: true
        end
        Crypt.const_set(:MissingNote, missing_note)

        expect(Crypt::Drawer.requires_encryption_schema?).to be true
      end
    end
  end
end
