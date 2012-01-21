require "spec_helper"

describe Mongoid::Errors::TooManyNestedAttributeRecords do

  describe "#message" do

    context "default" do

      let(:error) do
        described_class.new('Favorites', 5)
      end

      it "contains error message" do
        error.message.should
          include("Accept Nested Attributes for Favorites is limited to 5 records.")
      end
    end
  end
end
