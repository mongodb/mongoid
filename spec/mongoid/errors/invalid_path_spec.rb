require 'spec_helper'

describe Mongoid::Errors::InvalidPath do

  describe "#message" do

    let(:error) do
      described_class.new(Address)
    end

    it "contains the problem in the message" do
      error.message.should include("Having a root path assigned for Address")
    end

    it "contains the summary in the message" do
      error.message.should include("Mongoid has two different path objects")
    end

    it "contains the resolution in the message" do
      error.message.should include("Most likely your embedded model, Address")
    end
  end
end
