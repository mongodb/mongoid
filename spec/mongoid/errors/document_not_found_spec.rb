require "spec_helper"

describe Mongoid::Errors::DocumentNotFound do

  describe "#message" do

    let(:error) do
      described_class.new(Person, "3")
    end

    it "contains document not found" do
      error.message.should include("Document not found")
    end
  end
end
