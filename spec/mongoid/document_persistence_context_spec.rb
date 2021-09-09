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
end
