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
end
