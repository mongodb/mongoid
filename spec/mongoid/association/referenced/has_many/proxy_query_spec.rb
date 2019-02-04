# frozen_string_literal: true

require "spec_helper"
require_relative '../has_many_models'

describe Mongoid::Association::Referenced::HasMany::Proxy do
  context 'with primary_key and foreign_key given' do
    let(:company) { HmmCompany.create!(p: 123) }
    let(:criteria) { company.emails }

    it 'generates correct query' do
      expect(criteria.selector).to eq('f' => 123)
    end

    context 'unscoped' do
      let(:criteria) { company.emails.unscoped }

      it 'generates correct query' do
        expect(criteria.selector).to eq('f' => 123)
      end
    end
  end
end
