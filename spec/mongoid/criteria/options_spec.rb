# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Criteria::Options do


  context 'when a persistence context with options is set on the class of the criteria' do

    let(:context) do
      Band.with(connect_timeout: 10) do |klass|
        klass.where(name: 'FKA Twigs').persistence_context
      end
    end

    it 'uses the persistence context of the class of the criteria' do
      expect(context.options).to eq({ connect_timeout: 10 })
    end
  end

  context 'when a persistence context with options is not set on the class of the criteria' do

    let(:context) do
      Band.where(name: 'FKA Twigs').persistence_context
    end

    it 'uses the persistence context of the class of the criteria' do
      expect(context.options).to eq({ })
    end
  end
end
