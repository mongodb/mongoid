require "spec_helper"

describe Mongoid::Errors::InvalidTime do

  describe "#message" do

    let(:error) do
      described_class.new("this is not a date")
    end

    it "returns the invalid date message" do
      error.message.should include(
        "'this is not a date' is not a valid Time"
      )
    end
  end
end
