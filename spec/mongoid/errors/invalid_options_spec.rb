require "spec_helper"

describe Mongoid::Errors::InvalidOptions do

  describe "#message" do

    context "default" do

      let(:error) do
        described_class.new(:name, :invalid, [ :valid ])
      end

      it "returns the class name" do
        error.message.should include("Invalid option")
      end
    end
  end
end
