# frozen_string_literal: true

require 'spec_helper'
require_relative './reverse_population_spec_models'

describe 'Association reverse population' do
  describe 'has_many/belongs_to' do
    it 'populates child in parent' do
      company = ReversePopulationSpec::Company.create!
      email = ReversePopulationSpec::Email.create!(company: company)
      expect(company.emails).to eq([email])
    end
  end

  describe 'has_one/belongs_to' do
    it 'populates child in parent' do
      company = ReversePopulationSpec::Company.create!
      founder = ReversePopulationSpec::Founder.create!(company: company)
      expect(company.founder).to eq(founder)
    end
  end

  describe 'has_and_belongs_to_many' do
    it 'persists association on the other side' do
      animal = ReversePopulationSpec::Animal.create!
      zoo = ReversePopulationSpec::Zoo.create!
      animal.zoos << zoo
      animal.save!
      expect(zoo.animals).to eq([animal])
      zoo = ReversePopulationSpec::Zoo.find(zoo.id)
      expect(zoo.animals).to eq([animal])
    end
  end
end
