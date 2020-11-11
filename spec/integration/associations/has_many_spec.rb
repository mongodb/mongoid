# frozen_string_literal: true
# encoding: utf-8

require 'spec_helper'
require 'mongoid/association/referenced/has_many_models'

describe 'has_many associations' do
  context 'destroying parent in transaction with dependent child' do
    require_transaction_support

    let(:company) { HmmCompany.create! }
    let(:address) { HmmAddress.create!(company: company) }

    before do
      Company.delete_all
      Address.delete_all
    end

    context 'dependent: :destroy' do
      before do
        HmmCompany.class_eval do
          has_one :address, class_name: 'HmmAddress', dependent: :destroy
        end
      end

      it 'destroys' do
        address

        HmmCompany.count.should == 1
        HmmAddress.count.should == 1

        company.with_session do |session|
          session.with_transaction do
            company.destroy!
          end
        end

        HmmCompany.count.should == 0
        HmmAddress.count.should == 0
      end
    end

    context 'dependent: :restrict_with_error' do
      before do
        HmmCompany.class_eval do
          has_one :address, class_name: 'HmmAddress', dependent: :restrict_with_error
        end
      end

      it 'destroys' do
        address

        HmmCompany.count.should == 1
        HmmAddress.count.should == 1

        lambda do
          company.with_session do |session|
            session.with_transaction do
              company.destroy!
            end
          end
        end.should raise_error(Mongoid::Errors::DocumentNotDestroyed)

        HmmCompany.count.should == 1
        HmmAddress.count.should == 1
      end
    end
  end

  context 'when child does not have parent association' do
    context 'Child.new' do
      it 'creates a child instance' do
        HmmBusSeat.new.should be_a(HmmBusSeat)
      end
    end

    context 'assignment to child in parent' do
      let(:parent) { HmmBus.new }

      it 'raises InverseNotFound' do
        lambda do
          parent.seats << HmmBusSeat.new
        end.should raise_error(Mongoid::Errors::InverseNotFound)
      end
    end
  end
end
