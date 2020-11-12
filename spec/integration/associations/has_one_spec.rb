# frozen_string_literal: true
# encoding: utf-8

require 'spec_helper'
require 'mongoid/association/referenced/has_one_models'

describe 'has_one associations' do
  context 'destroying parent in transaction with dependent child' do
    require_transaction_support

    let(:college) { HomCollege.create! }
    let(:address) { HomAddress.create!(college: college) }

    before do
      HomCollege.delete_all
      HomAddress.delete_all
    end

    context 'dependent: :destroy' do
      before do
        HomCollege.class_eval do
          has_one :address, class_name: 'HomAddress', dependent: :destroy
        end
      end

      it 'destroys' do
        address

        HomCollege.count.should == 1
        HomAddress.count.should == 1

        HomCollege.with_session do |session|
          session.with_transaction do
            college.destroy!
          end
        end

        HomCollege.count.should == 0
        HomAddress.count.should == 0
      end
    end

    context 'dependent: :restrict_with_error' do
      before do
        HomCollege.class_eval do
          has_one :address, class_name: 'HomAddress', dependent: :restrict_with_error
        end
      end

      it 'does not destroy' do
        address

        HomCollege.count.should == 1
        HomAddress.count.should == 1

        lambda do
          HomCollege.with_session do |session|
            session.with_transaction do
              college.destroy!
            end
          end
        end.should raise_error(Mongoid::Errors::DocumentNotDestroyed)

        HomCollege.count.should == 1
        HomAddress.count.should == 1
      end
    end
  end

  context 'when child does not have parent association' do
    context 'Child.new' do
      it 'creates a child instance' do
        HomBusDriver.new.should be_a(HomBusDriver)
      end
    end

    context 'assignment to child in parent' do
      let(:parent) { HomBus.new }

      it 'raises InverseNotFound' do
        lambda do
          parent.driver = HomBusDriver.new
        end.should raise_error(Mongoid::Errors::InverseNotFound)
      end
    end
  end

  context 're-associating the same object' do
    context 'with dependent: destroy' do
      let(:person) do
        Person.create!
      end

      let!(:game) do
        Game.create!(person: person) do
          person.reload
        end
      end

      it 'does not destroy the dependent object' do
        person.game.should == game
        person.game = person.game
        person.save!
        person.reload
        person.game.should == game
      end
    end

    context 'without dependent: destroy' do
      let(:person) do
        Person.create!
      end

      let!(:account) do
        Account.create!(person: person, name: 'foo').tap do
          person.reload
        end
      end

      it 'does not destroy the dependent object' do
        person.account.should == account
        person.account = person.account
        person.save!
        person.reload
        person.account.should == account
      end
    end
  end
end
