require "spec_helper"

describe Mongoid::Errors::Validations do

  describe "#message" do

    let(:errors) do
      stub(:full_messages => [ "Error 1", "Error 2" ], :empty? => false)
    end

    let(:document) do
      stub(:errors => errors)
    end

    let(:error) do
      described_class.new(document)
    end

    it "contains the errors' full messages" do
      error.message.should eq("Validation failed - Error 1, Error 2.")
    end
  end
end
