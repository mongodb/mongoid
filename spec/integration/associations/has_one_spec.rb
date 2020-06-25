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
end
