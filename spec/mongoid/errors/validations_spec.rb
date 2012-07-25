require "spec_helper"

describe Mongoid::Errors::Validations do

  describe "#message" do

    let(:errors) do
      stub(full_messages: [ "Error 1", "Error 2" ], empty?: false)
    end

    let(:document) do
      stub(errors: errors, class: Person)
    end

    let(:error) do
      described_class.new(document)
    end

    it "contains the problem in the message" do
      error.message.should include(
        "Validation of Person failed"
      )
    end

    it "contains the summary in the message" do
      error.message.should include(
        "The following errors were found: Error 1, Error 2"
      )
    end

    it "contains the resolution in the message" do
      error.message.should include(
        "Try persisting the document with valid data"
      )
    end

    it "sets the document in the error" do
      error.document.should eq(document)
    end

    it "aliases record to document" do
      error.record.should eq(document)
    end
  end
end
