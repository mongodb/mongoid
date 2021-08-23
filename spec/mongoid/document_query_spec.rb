# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Document do

  context 'when projecting with #only' do
    before do
      Person.create!(username: 'Dev', title: 'CEO')
    end

    let(:person) { Person.where(username: 'Dev').only(:_id, :username).first }

    it 'populates specified fields only' do
      expect do
        person.title
      end.to raise_error(ActiveModel::MissingAttributeError)
      # has a default value specified in the model
      expect do
        person.age
      end.to raise_error(ActiveModel::MissingAttributeError)
      expect(person.attributes.keys).to eq(['_id', 'username'])
    end

    it 'allows writing omitted fields' do
      pending 'https://jira.mongodb.org/browse/MONGOID-4701'

      expect do
        person.age
      end.to raise_error(ActiveModel::MissingAttributeError)
      person.age = 42
      expect(person.age).to be 42
      person.save!
      _person = Person.find(person.id)
      expect(_person.age).to be 42
    end
  end

  context 'when projecting with #without' do
    before do
      duck = Pet.new(name: 'Duck')
      Person.create!(username: 'Dev', title: 'CEO', pet: duck)
    end

    let(:person) { Person.where(username: 'Dev').without(:title).first }

      it 'allows access to attribute of embedded document' do
      expect(person.pet.name).to eq 'Duck'
    end

    context 'when exclusion starts with association name but is not the association' do

      let(:person) { Person.where(username: 'Dev').without(:pet_).first }

      it 'allows access to attribute of embedded document' do
        expect(person.pet.name).to eq 'Duck'
      end
    end

    context 'when exclusion starts with prefix of association name' do

      let(:person) { Person.where(username: 'Dev').without(:pe).first }

      it 'allows access to attribute of embedded document' do
        expect(person.pet.name).to eq 'Duck'
      end
    end

    context 'when another attribute of the association is excluded' do

      let(:person) { Person.where(username: 'Dev').without('pet.weight').first }

      it 'allows access to non-excluded attribute of embedded document' do
        expect(person.pet.name).to eq 'Duck'
      end
    end

    context 'when the excluded attribute of the association is retrieved' do

      let(:person) { Person.where(username: 'Dev').without('pet.name').first }

      it 'prohibits the retrieval' do
        lambda do
          person.pet.name
        end.should raise_error(ActiveModel::MissingAttributeError)
      end
    end
  end
end
