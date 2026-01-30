# frozen_string_literal: true
# rubocop:todo all

require "spec_helper"

describe ActiveModel::Validations::NumericalityValidator do
  describe "#validate_each" do
    context "when allow_blank is false" do
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
        min_rails_version '6.1'

        let(:model) { TestModel.new(amount: BSON::Decimal128.new('15.0')) }

        it 'returns true' do
          expect(model).to be_valid
        end
      end
    end

    context "when allow_blank is true and amount is Integer" do
      before(:all) do
        class TestModelAllowBlankInteger
          include Mongoid::Document
          field :amount, type: Integer
          validates_numericality_of :amount, allow_blank: true
        end
      end

      after(:all) do
        Object.send(:remove_const, :TestModelAllowBlankInteger)
      end

      context "when the value is blank" do

        let(:model) do
          TestModelAllowBlankInteger.new(amount: "")
        end

        it "returns true" do
          expect(model).to be_valid
        end
      end

      context "when the value is a nonempty string" do

        let(:model) do
          TestModelAllowBlankInteger.new(amount: "A non-numeric string")
        end

        it "returns false" do
          expect(model).to_not be_valid
        end
      end
    end
 
    context "when allow_blank is true and amount is Float" do
      before(:all) do
        class TestModelAllowBlankFloat
          include Mongoid::Document
          field :amount, type: Float
          validates_numericality_of :amount, allow_blank: true
        end
      end

      after(:all) do
        Object.send(:remove_const, :TestModelAllowBlankFloat)
      end

      context "when the value is a nonempty string" do

        let(:model) do
          TestModelAllowBlankFloat.new(amount: "A non-numeric string")
        end

        it "returns false" do
          expect(model).to_not be_valid
        end
      end
    end

    context "when allow_blank is true and amount is BigDecimal" do
      before(:all) do
        class TestModelAllowBlankBigDecimal
          include Mongoid::Document
          field :amount, type: BigDecimal
          validates_numericality_of :amount, allow_blank: true
        end
      end

      after(:all) do
        Object.send(:remove_const, :TestModelAllowBlankBigDecimal)
      end

      context "when the value is a nonempty string" do

        let(:model) do
          TestModelAllowBlankBigDecimal.new(amount: "A non-numeric string")
        end

        it "returns false" do
          expect(model).to_not be_valid
        end
      end
    end
  end
end
