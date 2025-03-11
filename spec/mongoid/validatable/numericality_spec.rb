# frozen_string_literal: true
# rubocop:todo all

require "spec_helper"

describe ActiveModel::Validations::NumericalityValidator do

  describe "#validate_each" do

    before(:all) do
      class TestModel
        include Mongoid::Document
        field :amount, type: BigDecimal
        validates_numericality_of :amount, allow_blank: false
      end
    end

    after(:all) do
      Object.send(:remove_const, :TestModel)
    end

    context "when the value is non numeric" do

      let(:model) do
        TestModel.new(amount: "asdf")
      end

      it "returns false" do
        expect(model).to_not be_valid
      end
    end

    context 'when the value is numeric' do
      let(:model) { TestModel.new(amount: '15.0') }

      it 'returns true' do
        expect(model).to be_valid
      end
    end

    context 'when the value is a BSON::Decimal128' do
      let(:model) { TestModel.new(amount: BSON::Decimal128.new('15.0')) }

      it 'returns true' do
        expect(model).to be_valid
      end
    end
  end
end
