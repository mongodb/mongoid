# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Errors::InvalidFieldTypeDefinition do

  describe "#message" do

    context 'when field_type is the wrong type' do
      let(:error) do
        described_class.new(123, Integer)
      end

      it "contains the problem in the message" do
        expect(error.message).to include(
          "The field type definition of 123 to Integer is invalid."
        )
      end

      it "contains the summary in the message" do
        expect(error.message).to include(
          "In the field type definition, either field_type 123 is not a Symbol"
        )
      end

      it "contains the resolution in the message" do
        expect(error.message).to include(
          'Please ensure you are specifying field_type as either a Symbol'
        )
      end
    end

    context 'when klass is the wrong type' do
      let(:error) do
        described_class.new('number', 123)
      end

      it "contains the problem in the message" do
        expect(error.message).to include(
          'The field type definition of "number" to 123 is invalid.'
        )
      end

      it "contains the summary in the message" do
        expect(error.message).to include(
          'In the field type definition, either field_type "number" is not a Symbol'
        )
      end

      it "contains the resolution in the message" do
        expect(error.message).to include(
          'Please ensure you are specifying field_type as either a Symbol'
        )
      end
    end
  end
end
