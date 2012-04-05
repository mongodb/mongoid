require "spec_helper"

describe Mongoid::Errors::InvalidConfigOption do

  describe "#message" do

    let(:error) do
      described_class.new(:bad_option)
    end

    it "contains the problem in the message" do
      error.message.should include(
        "Invalid configuration option: bad_option."
      )
    end

    it "contains the summary in the message" do
      error.message.should include(
        "A invalid configuration option was provided in your mongoid.yml,"
      )
    end

    it "contains the resolution in the message" do
      error.message.should include(
        "Remove the invalid option or fix the typo."
      )
    end
  end
end
