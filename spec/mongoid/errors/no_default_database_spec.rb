require "spec_helper"

describe Mongoid::Errors::NoDefaultDatabase do

  describe "#message" do

    let(:error) do
      described_class.new([ :non_default ])
    end

    it "contains the problem in the message" do
      error.message.should include(
        "No default database configuration is defined."
      )
    end

    it "contains the summary in the message" do
      error.message.should include(
        "The configuration provided settings for: non_default"
      )
    end

    it "contains the resolution in the message" do
      error.message.should include(
        "If configuring via a mongoid.yml, ensure that within"
      )
    end
  end
end
