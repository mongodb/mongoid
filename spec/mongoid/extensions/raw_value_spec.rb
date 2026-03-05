# frozen_string_literal: true
# rubocop:todo all

require "spec_helper"

describe Mongoid::RawValue do

  describe "::()" do
    subject { Mongoid::RawValue(raw_value).raw_value }

    context 'when raw_value is a String' do
      let(:raw_value) { 'Hello World!' }

      it 'returns the value' do
        is_expected.to eq 'Hello World!'
      end
    end

    context 'when raw_value is an Integer' do
      let(:raw_value) { 42 }

      it 'returns the value' do
        is_expected.to eq 42
      end
    end
  end

  describe "#raw_value" do
    subject { described_class.new(raw_value).raw_value }

    context 'when raw_value is a String' do
      let(:raw_value) { 'Hello World!' }

      it 'returns the value' do
        is_expected.to eq 'Hello World!'
      end
    end

    context 'when raw_value is an Integer' do
      let(:raw_value) { 42 }

      it 'returns the value' do
        is_expected.to eq 42
      end
    end
  end

  describe "#inspect" do
    subject { described_class.new(raw_value).inspect }

    context 'when raw_value is a String' do
      let(:raw_value) { 'Hello World!' }

      it 'returns the inspection' do
        is_expected.to eq 'RawValue: "Hello World!"'
      end
    end

    context 'when raw_value is an Integer' do
      let(:raw_value) { 42 }

      it 'returns the inspection' do
        is_expected.to eq 'RawValue: 42'
      end
    end
  end
end
