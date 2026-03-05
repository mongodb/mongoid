# frozen_string_literal: true
# rubocop:todo all

require "spec_helper"

describe ActiveModel::Validations::NumericalityValidator do
  describe "#validate_each" do
    context "when allow_blank is false" do
      let(:model_class) do
        test_model do
          field :amount, type: BigDecimal
          validates_numericality_of :amount, allow_blank: false
        end
      end

      context "when the value is non numeric" do

        let(:model) do
          model_class.new(amount: "asdf")
        end

        it "returns false" do
          expect(model).to_not be_valid
        end
      end

      context 'when the value is numeric' do
        let(:model) { model_class.new(amount: '15.0') }

        it 'returns true' do
          expect(model).to be_valid
        end
      end

      context 'when the value is a BSON::Decimal128' do
        min_rails_version '6.1'

        let(:model) { model_class.new(amount: BSON::Decimal128.new('15.0')) }

        it 'returns true' do
          expect(model).to be_valid
        end
      end
    end

    context "when allow_blank is true and amount is Integer" do
      let(:model_class) do
        test_model do
          field :amount, type: Integer
          validates_numericality_of :amount, allow_blank: true
        end
      end

      context "when the value is blank" do

        let(:model) do
          model_class.new(amount: "")
        end

        it "returns true" do
          expect(model).to be_valid
        end
      end

      context "when the value is a nonempty string" do

        let(:model) do
          model_class.new(amount: "A non-numeric string")
        end

        it "returns false" do
          expect(model).to_not be_valid
        end
      end
    end

    context 'when allow_nil is true' do
      let(:model_class) do
        test_model do
          field :amount, type: Integer
          validates_numericality_of :amount, allow_nil: true
        end
      end

      context 'when the value is blank' do
        let(:model) do
          model_class.new(amount: '')
        end

        it 'is invalid' do
          expect(model).to_not be_valid
        end
      end

      context 'when the value is nil' do
        let(:model) do
          model_class.new(amount: nil)
        end

        it 'is valid' do
          expect(model).to be_valid
        end
      end
    end
 
    context "when allow_blank is true and amount is Float" do
      let(:model_class) do
        test_model do
          field :amount, type: Float
          validates_numericality_of :amount, allow_blank: true
        end
      end

      context "when the value is a nonempty string" do

        let(:model) do
          model_class.new(amount: "A non-numeric string")
        end

        it "returns false" do
          expect(model).to_not be_valid
        end
      end
    end

    context "when allow_blank is true and amount is BigDecimal" do
      let(:model_class) do
        test_model do
          field :amount, type: BigDecimal
          validates_numericality_of :amount, allow_blank: true
        end
      end

      context "when the value is a nonempty string" do

        let(:model) do
          model_class.new(amount: "A non-numeric string")
        end

        it "returns false" do
          expect(model).to_not be_valid
        end
      end
    end
  end
end
