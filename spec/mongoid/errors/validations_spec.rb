# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Errors::Validations do

  describe "#message" do

    let(:errors) do
      double(full_messages: [ "Error 1", "Error 2" ], empty?: false)
    end

    let(:document) do
      double(errors: errors, class: Person)
    end

    let(:error) do
      described_class.new(document)
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "Validation of Person failed"
      )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
        "The following errors were found: Error 1, Error 2"
      )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        "Try persisting the document with valid data"
      )
    end

    it "sets the document in the error" do
      expect(error.document).to eq(document)
    end

    it "aliases record to document" do
      expect(error.record).to eq(document)
    end
  end
end
