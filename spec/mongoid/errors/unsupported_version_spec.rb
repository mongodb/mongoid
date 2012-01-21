require "spec_helper"

describe Mongoid::Errors::UnsupportedVersion do

  describe "#message" do

    let(:version) do
      Mongo::ServerVersion.new("1.2.4")
    end

    let(:error) do
      described_class.new(version)
    end

    it "returns a message with the bad version and good version" do
      error.message.should eq(
        "MongoDB 1.2.4 not supported, please upgrade to #{Mongoid::MONGODB_VERSION}."
      )
    end
  end
end
