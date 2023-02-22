# frozen_string_literal: true

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

        expect(HmmCompany.count).to eq(1)
        expect(HmmAddress.count).to eq(1)

        company.with_session do |session|
          session.with_transaction do
            company.destroy!
          end
        end

        expect(HmmCompany.count).to eq(0)
        expect(HmmAddress.count).to eq(0)
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

        expect(HmmCompany.count).to eq(1)
        expect(HmmAddress.count).to eq(1)

        expect do
          company.with_session do |session|
            session.with_transaction do
              company.destroy!
            end
          end
        end.to raise_error(Mongoid::Errors::DocumentNotDestroyed)

        expect(HmmCompany.count).to eq(1)
        expect(HmmAddress.count).to eq(1)
      end
    end
  end

  context 'when child does not have parent association' do
    context 'Child.new' do
      it 'creates a child instance' do
        expect(HmmBusSeat.new).to be_a(HmmBusSeat)
      end
    end

    context 'assignment to child in parent' do
      let(:parent) { HmmBus.new }

      it 'raises InverseNotFound' do
        expect do
          parent.seats << HmmBusSeat.new
        end.to raise_error(Mongoid::Errors::InverseNotFound)
      end
    end
  end

  context 're-associating the same object' do
    context 'with dependent: destroy' do
      let(:wiki_page) do
        WikiPage.create!
      end

      let!(:comment) do
        Comment.create!(wiki_page: wiki_page, title: 'hi') do
          wiki_page.reload
        end
      end

      it 'does not destroy the dependent object' do
        expect(wiki_page.comments).to eq([comment])
        wiki_page.comments = [comment]
        wiki_page.save!
        wiki_page.reload
        expect(wiki_page.comments).to eq([comment])
      end
    end

    context 'without dependent: destroy' do
      let(:series) do
        Series.create!
      end

      let!(:book) do
        Book.create!(series: series).tap do
          series.reload
        end
      end

      it 'does not destroy the dependent object' do
        expect(series.books).to eq([book])
        series.books = [book]
        series.save!
        series.reload
        expect(series.books).to eq([book])
      end
    end
  end
end
