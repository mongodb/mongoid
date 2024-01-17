# frozen_string_literal: true
# rubocop:todo all

require "spec_helper"

describe Mongoid::Document do

  let(:klass) do
    Person
  end

  let(:person) do
    Person.new
  end

  describe '.client_name' do
    it 'returns client name' do
      Person.client_name.should == :default
    end
  end

  describe '.database_name' do
    it 'returns database name' do
      Person.database_name.should == 'mongoid_test'
    end
  end

  describe '.collection_name' do
    it 'returns collection name' do
      Person.collection_name.should == :people
    end
  end

  context 'when loaded with an overridden persistence context' do
    let(:options) { { collection: 'extra_people' } }
    let(:person) { Person.with(options) { Person.create username: 'zyg14' } }

    # Mongoid 9+ default persistence behavior
    context 'when Mongoid.legacy_persistence_context_behavior is false' do
      config_override :legacy_persistence_context_behavior, false

      it 'remembers its persistence context when created' do
        expect(person.collection_name).to be == :extra_people
      end

      it 'remembers its context when queried specifically' do
        person_by_id = Person.with(options) { Person.find(_id: person._id) }
        expect(person_by_id.collection_name).to be == :extra_people
      end

      it 'remembers its context when queried generally' do
        person # force the person to be created
        person_generally = Person.with(options) { Person.all[0] }
        expect(person_generally.collection_name).to be == :extra_people
      end

      it 'can be reloaded without specifying the context' do
        expect { person.reload }.not_to raise_error
        expect(person.collection_name).to be == :extra_people
      end

      it 'can be updated without specifying the context' do
        person.update username: 'zyg15'
        expect(Person.with(options) { Person.first.username }).to be == 'zyg15'
      end

      it 'an explicit context takes precedence over a remembered context when persisting' do
        person.username = 'bob'
        # should not actually save -- the person does not exist in the
        # `other` collection and so cannot be updated.
        Person.with(collection: 'other') { person.save! }
        expect(person.reload.username).to eq 'zyg14'
      end

      it 'an explicit context takes precedence over a remembered context when reloading' do
        expect { Person.with(collection: 'other') { person.reload } }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end

    # pre-9.0 default persistence behavior
    context 'when Mongoid.legacy_persistence_context_behavior is true' do
      config_override :legacy_persistence_context_behavior, true

      it 'does not remember its persistence context when created' do
        expect(person.collection_name).to be == :people
      end

      it 'does not remember its context when queried specifically' do
        person_by_id = Person.with(options) { Person.find(_id: person._id) }
        expect(person_by_id.collection_name).to be == :people
      end

      it 'does not remember its context when queried generally' do
        person # force the person to be created
        person_generally = Person.with(options) { Person.all[0] }
        expect(person_generally.collection_name).to be == :people
      end

      it 'cannot be reloaded without specifying the context' do
        expect { person.reload }.to raise_error
      end

      it 'cannot be updated without specifying the context' do
        person.update username: 'zyg15'
        expect(Person.with(options) { Person.first.username }).to be == 'zyg14'
      end
    end
  end
end
