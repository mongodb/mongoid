# frozen_string_literal: true

require 'spec_helper'

describe 'has_and_belongs_to_many associations' do

  context 'when an anonymous class defines a has_and_belongs_to_many association' do
    let(:klass) do
      Class.new do
        include Mongoid::Document
        has_and_belongs_to_many :movies, inverse_of: nil
      end
    end

    it 'loads the association correctly' do
      expect { klass }.to_not raise_error
      expect { klass.new.movies }.to_not raise_error
      expect(klass.new.movies.build).to be_a Movie
    end
  end
end
