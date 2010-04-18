require "spec_helper"

describe Mongoid::Extensions::Hash::Conversions do

  describe "#difference" do

    let(:first) do
      { :field1 => "old1", :field2 => "old2", :field3 => "old3" }
    end

    let(:second) do
      { :field1 => "new1", :field2 => "new2" }
    end

    it "returns a new hash of keys with old and new values" do
      first.difference(second).should ==
        { :field1 => [ "old1", "new1" ], :field2 => [ "old2", "new2" ] }
    end
  end

  describe ".get" do

    it "returns the hash" do
      Hash.get({ :field => "test" }).should == { :field => "test" }
    end

  end

  describe ".set" do

    it "returns the hash" do
      Hash.set({ :field => "test" }).should == { :field => "test" }
    end
  end
end
