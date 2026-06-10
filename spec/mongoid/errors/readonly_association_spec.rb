# frozen_string_literal: true

require 'spec_helper'

describe Mongoid::Errors::ReadonlyAssociation do
  let(:owner_class) do
    Class.new do
      def self.to_s
        'SomeOwner'
      end
    end
  end

  let(:association) do
    double(name: :patients, options: { through: :appointments })
  end

  describe '#message' do
    it 'names the association' do
      error = described_class.new(owner_class, association)
      expect(error.message).to include(':patients')
    end

    it 'names the owner class' do
      error = described_class.new(owner_class, association)
      expect(error.message).to include('SomeOwner')
    end

    it 'names the intermediate association' do
      error = described_class.new(owner_class, association)
      expect(error.message).to include(':appointments')
    end
  end
end
