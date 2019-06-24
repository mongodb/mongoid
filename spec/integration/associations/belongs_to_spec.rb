# frozen_string_literal: true
# encoding: utf-8

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
end
