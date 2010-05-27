require "spec_helper"

describe Mongoid::Extensions::Set::Conversions do

  describe "#get" do

    it "returns the set if Array" do
      Set.get(["test"]).should == Set.new(["test"])
    end

  end

  describe "#set" do

    it "returns an array" do
      Set.set(["test"]).should == ["test"]
    end

  end

end
