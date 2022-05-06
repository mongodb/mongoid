# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Errors::InvalidFieldType do

  describe "#message" do

    let(:error) do
      described_class.new(Person, :first_name, :stringgy)
    end

    context 'when type is a symbol' do
      let(:error) do
        described_class.new(Person, :first_name, :stringgy)
      end

      it "contains the problem in the message" do
        expect(error.message).to include(
          "Invalid field type :stringgy for field 'first_name' on model 'Person'."
        )
      end

      it "contains the summary in the message" do
        expect(error.message).to include(
          "Model 'Person' defines a field 'first_name' with an unknown type value :stringgy."
        )
      end
    end

    context 'when type is a string' do
      let(:error) do
        described_class.new(Person, :first_name, 'stringgy')
      end

      it "contains the problem in the message" do
        expect(error.message).to include(
          %q,Invalid field type "stringgy" for field 'first_name' on model 'Person'.,
        )
      end

      it "contains the summary in the message" do
        expect(error.message).to include(
          %q,Model 'Person' defines a field 'first_name' with an unknown type value "stringgy".,
        )
      end
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        'Please provide a valid type value for the field.'
      )
    end
  end
end
