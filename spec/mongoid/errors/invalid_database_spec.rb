require "spec_helper"

describe Mongoid::Errors::InvalidDatabase do

  describe "#message" do

    let(:error) do
      described_class.new("Test")
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "Database should be a Mongo::DB, not String."
      )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
        "When setting a master database in the Mongoid configuration"
      )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        "Make sure that when setting the configuration programatically"
      )
    end
  end
end
