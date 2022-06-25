# frozen_string_literal: true

require 'spec_helper'
require_relative '../../mongoid/association/referenced/has_one_models'

describe 'belongs_to associations' do
  context 'referencing top level classes when source class is namespaced' do
    let(:college) { HomCollege.create! }
    let(:child) { HomAccreditation::Child.new(hom_college: college) }

    it 'works' do
      expect(child).to be_valid
    end
  end

  context 'when an anonymous class defines a belongs_to association' do
    let(:klass) do
      Class.new do
        include Mongoid::Document
        belongs_to :movie
      end
    end

    it 'loads the association correctly' do
      expect { klass }.to_not raise_error
      expect { klass.new.movie }.to_not raise_error
      instance = klass.new
      movie = Movie.new
      instance.movie = movie
      expect(instance.movie).to eq movie
    end
  end
end
