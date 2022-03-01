# frozen_string_literal: true

require 'spec_helper'
require_relative './foreign_key_spec_models'

describe 'Association foreign key configuration' do
  describe 'has_many/belongs_to' do
    it 'creates child' do
      company = ForeignKeySpec::Company.create!(c: 'test')
      email = ForeignKeySpec::Email.create!(company: company)
      expect(email.c_ref).to eq('test')
    end

    it 'looks up child' do
      company = ForeignKeySpec::Company.create!(c: 'test')
      email = ForeignKeySpec::Email.create!(company: company)

      company = ForeignKeySpec::Company.find(company.id)
      expect(company.emails.first.id).to eq(email.id)
    end

    it 'looks up parent' do
      company = ForeignKeySpec::Company.create!(c: 'test')
      email = ForeignKeySpec::Email.create!(company: company)

      email = ForeignKeySpec::Email.find(email.id)
      expect(email.company.id).to eq(company.id)
    end

    it "has the correct criteria" do
      company = ForeignKeySpec::Company.create!(c: "3")
      email = ForeignKeySpec::Email.create!(company: company)

      criteria = ForeignKeySpec::Email.where(company: company)

      expect(criteria.selector).to eq({ "c_ref" => "3" })
    end

    context 'with default scope' do
      context 'using default scope' do
        it 'looks up child' do
          company = ForeignKeySpec::ScopedCompany.create!(c: 'test')
          on_email = ForeignKeySpec::ScopedEmail.create!(company: company, s: 'on')
          off_email = ForeignKeySpec::ScopedEmail.create!(company: company, s: 'off')

          company = ForeignKeySpec::ScopedCompany.find(company.id)
          expect(company.emails.length).to eq(1)
          expect(company.emails.first.id).to eq(on_email.id)
        end
      end

      context 'unscoped' do
        it 'looks up child' do
          company = ForeignKeySpec::ScopedCompany.create!(c: 'test')
          on_email = ForeignKeySpec::ScopedEmail.create!(company: company, s: 'on')
          off_email = ForeignKeySpec::ScopedEmail.create!(company: company, s: 'off')

          company = ForeignKeySpec::ScopedCompany.find(company.id)
          expect(company.emails.unscoped.length).to eq(2)
          expect(company.emails.unscoped.map(&:id).sort).to eq([on_email.id, off_email.id].sort)
        end
      end
    end
  end

  describe 'has_one/belongs_to' do
    it 'creates child' do
      company = ForeignKeySpec::Company.create!(c: 'test')
      founder = ForeignKeySpec::Founder.create!(company: company)
      expect(founder.c_ref).to eq('test')
    end

    it 'looks up child' do
      company = ForeignKeySpec::Company.create!(c: 'test')
      founder = ForeignKeySpec::Founder.create!(company: company)

      company = ForeignKeySpec::Company.find(company.id)
      expect(company.founder.id).to eq(founder.id)
    end

    it 'looks up parent' do
      company = ForeignKeySpec::Company.create!(c: 'test')
      founder = ForeignKeySpec::Founder.create!(company: company)

      email = ForeignKeySpec::Founder.find(founder.id)
      expect(founder.company.id).to eq(company.id)
    end
  end

  describe 'has_and_belongs_to_many' do
    it 'persists association on the other side' do
      animal = ForeignKeySpec::Animal.create!(a: 'bear')
      zoo = ForeignKeySpec::Zoo.create!(z: 'bz')
      animal.zoos << zoo
      animal.save!

      # This write should not be necessary, but without it the test fails.
      # https://jira.mongodb.org/browse/MONGOID-4648
      zoo.animals << animal
      zoo.save!

      expect(zoo.animals).to eq([animal])
      zoo = ForeignKeySpec::Zoo.find(zoo.id)
      expect(zoo.animals).to eq([animal])
    end
  end
end
