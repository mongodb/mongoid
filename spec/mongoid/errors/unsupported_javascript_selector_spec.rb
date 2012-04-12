require "spec_helper"

describe Mongoid::Errors::UnsupportedJavascriptSelector do

  describe "#message" do

    let(:error) do
      described_class.new(Address)
    end

    it "contains the problem in the message" do
      error.message.should include(
        "Unsupported Javascript selector in the embedded document Address."
      )
    end

    it "contains the summary in the message" do
      error.message.should include(
        "Javascript criteria selector is only supported in native MongoDB queries."
      )
    end

    it "contains the resolution in the message" do
      error.message.should include(
        "Use a Hash selector in your criteria."
      )
    end
  end
end
