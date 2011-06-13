require "spec_helper"

describe Mongoid::Extensions::Range::Conversions do

  describe ".try_bson" do

    it "returns the range" do
      Range.try_bson({"min" => 1, "max" => 3}).should == (1..3)
    end
  end

  describe ".from_bson" do

    context "when the value is not nil" do

      it "returns the object to_hash" do
        Range.from_bson(1..3).should == {"min" => 1, "max" => 3}
      end
    end

    context "when the value is nil" do

      it "returns nil" do
        Range.from_bson(nil).should be_nil
      end
    end
  end

  describe "#to_hash" do

    let(:range) do
      1..3
    end

    it "returns an hash with the min and max values" do
      range.to_hash.should == {"min" => 1, "max" => 3}
    end
  end
end
