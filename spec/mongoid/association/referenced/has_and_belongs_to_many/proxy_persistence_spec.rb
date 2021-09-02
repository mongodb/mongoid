# frozen_string_literal: true

require "spec_helper"
require_relative '../has_and_belongs_to_many_models'

describe Mongoid::Association::Referenced::HasAndBelongsToMany::Proxy do
  context 'with primary_key and foreign_key given' do
    let(:company) { HabtmmCompany.create!(c_id: 123) }
    let(:employee) { HabtmmEmployee.create!(e_id: 456) }

    before do
      company.employees << employee
    end

    it 'references correct field' do
      expect(company.e_ids).to eq([456])
    end

    describe '#nullify' do
      before do
        company.employees << repl_employee
        company.save!
        expect(company.employees.length).to eq(2)
        repl_employee.c_ids = [company.c_id]
        repl_employee.save!
        repl_employee.reload
        expect(repl_employee.c_ids).to eq([123])
      end

      context 'without replacement' do
        let(:repl_employee) { HabtmmEmployee.create!(e_id: 444) }

        it 'disassociates child from parent' do
          company.employees.nullify
          repl_employee.reload
          expect(repl_employee.c_ids).to eq([])
        end
      end

      context 'with replacement' do
        let(:repl_employee) { HabtmmEmployee.create!(e_id: 444) }

        before do
          company.employees << repl_employee
          expect(company.employees.length).to eq(2)
        end

        it 'keeps replacement associated with the parent' do
          company.employees.nullify([repl_employee])
          repl_employee.reload
          expect(repl_employee.c_ids).to eq([123])
        end
      end
    end
  end

  describe '#<<' do
    let(:dog) { Dog.create! }
    let(:breed) { Breed.create! }

    it 'adds association on both ends' do
      dog.breeds << breed
      expect(breed.dogs).to eq([dog])
    end

    context 'with primary_key and foreign_key given' do
      let(:company) { HabtmmCompany.create!(c_id: 123) }
      let(:employee) { HabtmmEmployee.create!(e_id: 456) }

      it 'adds association on both ends' do
        company.employees << employee
        expect(employee.companies).to eq([company])
      end
    end
  end
end
