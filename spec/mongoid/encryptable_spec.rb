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
  end
end
