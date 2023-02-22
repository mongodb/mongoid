# frozen_string_literal: true

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
      expect(Person.client_name).to eq(:default)
    end
  end

  describe '.database_name' do
    it 'returns database name' do
      expect(Person.database_name).to eq('mongoid_test')
    end
  end

  describe '.collection_name' do
    it 'returns collection name' do
      expect(Person.collection_name).to eq(:people)
    end
  end
end
