# frozen_string_literal: true
# encoding: utf-8

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
end
