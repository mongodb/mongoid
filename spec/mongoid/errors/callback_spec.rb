require "spec_helper"

describe Mongoid::Errors::Callback do

  describe "#message" do

    let(:error) do
      described_class.new(Post, :create!)
    end

    it "contains the problem in the message" do
      expect(error.message).to include(
        "Calling create! on Post resulted in a false return from a callback."
      )
    end

    it "contains the summary in the message" do
      expect(error.message).to include(
        "If a before callback returns false when using Document.create!"
      )
    end

    it "contains the resolution in the message" do
      expect(error.message).to include(
        "Double check all before callbacks to make sure they are not"
      )
    end
  end
end
