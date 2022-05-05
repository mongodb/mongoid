# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Fields::FieldTypes do

  after do
    described_class.instance_variable_set(:@mapping, described_class::DEFAULT_MAPPING.dup)
  end

  describe '.get' do
    subject { described_class.get(type) }

    context 'when value is a default mapped symbol' do
      let(:type) { :float }

      it 'uses the default mapped type' do
        is_expected.to eq Float
      end
    end

    context 'when value is a default mapped string' do
      let(:type) { 'double' }

      it 'uses the default mapped type' do
        is_expected.to eq Float
      end
    end

    context 'when value is a custom mapped symbol' do
      before { described_class.define('number', Integer) }
      let(:type) { :number }

      it 'uses the custom mapped type' do
        is_expected.to eq Integer
      end
    end

    context 'when value is a custom mapped string' do
      before { described_class.define(:number, Float) }
      let(:type) { 'number' }

      it 'uses the custom mapped type' do
        is_expected.to eq Float
      end
    end

    context 'when value is an unmapped symbol' do
      let(:type) { :my_value }

      it 'returns nil' do
        is_expected.to eq nil
      end
    end

    context 'when value is a unmapped string' do
      let(:type) { 'my_value' }

      it 'returns nil' do
        is_expected.to eq nil
      end
    end

    context 'when value is a module' do
      let(:type) { String }

      it 'uses the module type' do
        is_expected.to eq String
      end

      context 'deprecation' do
        around do |example|
          old_types = described_class.instance_variable_get(:@warned_class_types)
          described_class.instance_variable_set(:@warned_class_types, [])
          example.run
          described_class.instance_variable_set(:@warned_class_types, old_types)
        end

        it 'warns deprecation for the class type once' do
          expect(Mongoid.logger).to receive(:warn).once.with(match(/\AUsing a Class \(String\)/))
          described_class.get(String)
          described_class.get(String)
          expect(Mongoid.logger).to receive(:warn).once.with(match(/\AUsing a Class \(Integer\)/))
          described_class.get(Integer)
          described_class.get(String)
          described_class.get(Integer)
        end
      end
    end

    context 'when value is the module Boolean' do
      let(:type) do
        stub_const('Boolean', Module.new)
        Boolean
      end

      it 'returns Mongoid::Boolean type' do
        is_expected.to eq Mongoid::Boolean
      end
    end

    context 'when value is nil' do
      let(:type) { nil }

      it 'returns Object type' do
        is_expected.to eq Object
      end
    end
  end

  describe '.define' do

    it 'can define a new type' do
      described_class.define(:my_string, String)
      expect(described_class.get(:my_string)).to eq String
    end

    it 'can override a default type' do
      described_class.define(:integer, String)
      expect(described_class.get(:integer)).to eq String
    end

    it 'does not alter the DEFAULT_MAPPING constant' do
      described_class.define(:integer, String)
      expect(described_class::DEFAULT_MAPPING[:integer]).to eq Integer
    end
  end

  describe '.delete' do

    it 'can delete a custom type' do
      described_class.define(:my_string, String)
      expect(described_class.get(:my_string)).to eq String
      described_class.delete('my_string')
      expect(described_class.get(:my_string)).to eq nil
    end

    it 'can delete a default type' do
      described_class.delete(:integer)
      expect(described_class.get(:integer)).to eq nil
    end

    it 'does not alter the DEFAULT_MAPPING constant' do
      described_class.delete(:integer)
      expect(described_class::DEFAULT_MAPPING[:integer]).to eq Integer
    end
  end
end
