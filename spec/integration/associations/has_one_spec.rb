# frozen_string_literal: true
# encoding: utf-8

require 'spec_helper'

describe 'has_one associations' do
  context 'destroying parent in transaction with dependent child' do
    require_transaction_support

    let(:person) { Person.create! }
    let(:game) { Game.create!(person: person) }

    before do
      Person.delete_all
      Game.delete_all

      game
    end

    it 'works' do
      Person.count.should == 1
      Game.count.should == 1

      Person.with_session do |session|
        session.with_transaction do
          person.destroy
        end
      end

      Person.count.should == 0
      Game.count.should == 0
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
