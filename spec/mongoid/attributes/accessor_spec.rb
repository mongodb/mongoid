# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Lint/ConstantDefinitionInBlock, RSpec/LeakyConstantDeclaration
describe 'Strategy Pattern Implementation' do
  before(:all) do
    class TestPerson
      include Mongoid::Document
      field :name, type: String
      field :age, type: Integer
      field :score, type: Float
    end
  end

  after(:all) do
    Object.send(:remove_const, :TestPerson)
  end
  # rubocop:enable Lint/ConstantDefinitionInBlock, RSpec/LeakyConstantDeclaration

  describe 'with caching disabled' do
    before do
      Mongoid::Config.cache_attribute_values = false
    end

    it 'uses Accessor strategy' do
      person = TestPerson.new(name: 'John', age: 30)
      expect(person.attribute_accessor).to be_a(Mongoid::Attributes::Accessor)
      expect(person.attribute_accessor).not_to be_a(Mongoid::Attributes::CachingAccessor)
    end

    it 'reads attributes correctly' do
      person = TestPerson.new(name: 'John', age: 30)
      expect(person.name).to eq('John')
      expect(person.age).to eq(30)
    end

    it 'writes attributes correctly' do
      person = TestPerson.new
      person.name = 'Jane'
      person.age = 25
      expect(person.name).to eq('Jane')
      expect(person.age).to eq(25)
    end
  end

  describe 'with caching enabled' do
    before do
      Mongoid::Config.cache_attribute_values = true
    end

    after do
      Mongoid::Config.cache_attribute_values = false
    end

    it 'uses CachingAccessor strategy' do
      person = TestPerson.new(name: 'John', age: 30)
      expect(person.attribute_accessor).to be_a(Mongoid::Attributes::CachingAccessor)
    end

    it 'reads attributes correctly' do
      person = TestPerson.new(name: 'John', age: 30)
      expect(person.name).to eq('John')
      expect(person.age).to eq(30)
    end

    it 'writes attributes correctly' do
      person = TestPerson.new
      person.name = 'Jane'
      person.age = 25
      expect(person.name).to eq('Jane')
      expect(person.age).to eq(25)
    end

    it 'invalidates cache on write' do
      person = TestPerson.new(name: 'John', age: 30)

      # Read to populate cache
      expect(person.name).to eq('John')

      # Write should invalidate cache
      person.name = 'Jane'
      expect(person.name).to eq('Jane')
    end

    it 'invalidates cache on remove_attribute' do
      person = TestPerson.new(name: 'John', age: 30)

      # Read to populate cache
      expect(person.name).to eq('John')

      # Remove should invalidate cache
      person.remove_attribute(:name)
      expect(person.name).to be_nil
    end

    it 'resets cache on reload' do
      person = TestPerson.create!(name: 'John', age: 30)

      # Read to populate cache
      expect(person.name).to eq('John')

      # Update in database
      TestPerson.collection.find(_id: person.id).update_one('$set' => { 'name' => 'Jane' })

      # Reload should reset cache and reflect new value
      person.reload
      expect(person.name).to eq('Jane')

      person.delete
    end
  end

  describe 'when configuration changes after document creation' do
    after do
      # Ensure configuration is reset so other specs are not affected
      Mongoid::Config.cache_attribute_values = false
    end

    it 'uses accessor strategy corresponding to config at document creation time' do
      Mongoid::Config.cache_attribute_values = false
      person = TestPerson.new(name: 'John', age: 30)

      # Accessor should be initialized during document creation
      expect(person.attribute_accessor).to be_a(Mongoid::Attributes::Accessor)
      expect(person.attribute_accessor).not_to be_a(Mongoid::Attributes::CachingAccessor)

      # Change configuration after document creation
      Mongoid::Config.cache_attribute_values = true

      # Should still use the accessor from creation time
      expect(person.attribute_accessor).to be_a(Mongoid::Attributes::Accessor)
      expect(person.name).to eq('John')
    end

    it 'new documents use new configuration' do
      Mongoid::Config.cache_attribute_values = false
      person1 = TestPerson.new(name: 'John', age: 30)

      # Change configuration
      Mongoid::Config.cache_attribute_values = true
      person2 = TestPerson.new(name: 'Jane', age: 25)

      # First document uses old config, second uses new config
      expect(person1.attribute_accessor).to be_a(Mongoid::Attributes::Accessor)
      expect(person2.attribute_accessor).to be_a(Mongoid::Attributes::CachingAccessor)
    end

    it 'database-loaded documents use config at load time' do
      # Create with caching disabled
      Mongoid::Config.cache_attribute_values = false
      person = TestPerson.create!(name: 'John', age: 30)
      person_id = person.id

      # Enable caching before loading from database
      Mongoid::Config.cache_attribute_values = true

      # Document loaded from database should use caching accessor
      loaded_person = TestPerson.find(person_id)
      expect(loaded_person.attribute_accessor).to be_a(Mongoid::Attributes::CachingAccessor)
      expect(loaded_person.name).to eq('John')

      loaded_person.delete
    end
  end
end
