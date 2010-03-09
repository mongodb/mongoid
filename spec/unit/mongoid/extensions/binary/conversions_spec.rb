require "spec_helper"

describe Mongoid::Extensions::Binary::Conversions do

  let(:bin) do
    Binary.new
  end

  describe "#get" do

    it "returns self" do
      Binary.get(bin).should == bin
    end
  end

  describe "#set" do

    it "returns self" do
      Binary.set(bin).should == bin
    end
  end
end
