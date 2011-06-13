require "spec_helper"

describe Mongoid::Extensions::Binary::Conversions do

  let(:bin) do
    Binary.new
  end

  describe "#get" do

    it "returns self" do
      Binary.try_bson(bin).should == bin
    end
  end

  describe "#set" do

    it "returns self" do
      Binary.from_bson(bin).should == bin
    end
  end
end
