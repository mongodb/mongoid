require "spec_helper"

describe Mongoid::Errors::MixedSessionConfiguration do

  describe "#message" do

    let(:error) do
      described_class.new(:testing, { uri: "blah" })
    end

    it "contains the problem in the message" do
      error.message.should include(
        "Both uri and standard configuration options defined"
      )
    end

    it "contains the summary in the message" do
      error.message.should include(
        "Instead of simply giving uri or standard options a preference"
      )
    end

    it "contains the resolution in the message" do
      error.message.should include(
        "Provide either only a uri as configuration"
      )
    end
  end
end
