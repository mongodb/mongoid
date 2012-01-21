require "spec_helper"

describe Mongoid::Errors::InvalidField do

  describe "#message" do

    context "default" do

      let(:error) do
        described_class.new("collection")
      end

      it "contains class is not allowed" do
        error.message.should include("field named collection is not allowed")
      end
    end
  end
end
