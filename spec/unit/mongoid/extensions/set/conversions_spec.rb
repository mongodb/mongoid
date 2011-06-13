require "spec_helper"

describe Mongoid::Extensions::Set::Conversions do

  describe "#get" do

    it "returns the set if Array" do
      Set.try_bson(["test"]).should == Set.new(["test"])
    end

  end

  describe "#set" do

    it "returns an array" do
      Set.from_bson(["test"]).should == ["test"]
    end

    it "returns an array even if the value is a set" do
      Set.from_bson(Set.new(["test"])) == ["test"]
    end

  end

end
