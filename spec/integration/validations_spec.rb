# rubocop:todo all
# frozen_string_literal: true

require 'spec_helper'
require_relative './validations_spec_models'

describe 'validations' do

  context 'when validating presence of has_and_belongs_to_many association' do
    let(:company) { ValidationsSpecModels::Company.create! }
    let(:client) { ValidationsSpecModels::Client.create!(companies: [company]) }

    context 'when updating the association' do
      it 'raises an error' do
        expect { client.update!(companies: []) }.to raise_error(Mongoid::Errors::Validations)
      end

      it 'does not persist the changes' do
        expect { client.update!(companies: []) rescue nil }.not_to change { client.reload.companies }
      end
    end
  end


  context 'when validating presence of has_many association' do
    let(:apartment) { ValidationsSpecModels::Apartment.create! }
    let(:building) { ValidationsSpecModels::Building.create!(apartments: [apartment]) }

    context 'when updating the association' do
      it 'raises an error' do
        expect { building.update!(apartments: []) }.to raise_error(Mongoid::Errors::Validations)
      end

      it 'does not persist the changes' do
        expect { building.update!(apartments: []) rescue nil }.not_to change { building.reload.apartments }
      end
    end
  end
end
