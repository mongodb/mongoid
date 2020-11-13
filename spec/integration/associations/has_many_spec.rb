# frozen_string_literal: true
# encoding: utf-8

require 'spec_helper'

describe 'has_many associations' do
  context 'destroying parent in transaction with dependent child' do
    require_transaction_support

    let(:artist) { Artist.create! }
    let(:album) { Album.create!(artist: artist) }

    before do
      Artist.delete_all
      Album.delete_all

      album
    end

    it 'works' do
      Artist.count.should == 1
      Album.count.should == 1

      artist.with_session do |session|
        session.with_transaction do
          artist.destroy
        end
      end

      Artist.count.should == 0
      Album.count.should == 0
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
        wiki_page.comments.should == [comment]
        wiki_page.comments = [comment]
        wiki_page.save!
        wiki_page.reload
        wiki_page.comments.should == [comment]
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
        series.books.should == [book]
        series.books = [book]
        series.save!
        series.reload
        series.books.should == [book]
      end
    end
  end
end
