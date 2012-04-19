require "spec_helper"

describe Mongoid::Extensions::Set do

  describe "#demongoize" do

    it "returns the set if Array" do
      Set.demongoize([ "test" ]).should eq(Set.new([ "test" ]))
    end
  end

  describe ".mongoize" do

    it "returns an array" do
      Set.mongoize([ "test" ]).should eq([ "test" ])
    end

    it "returns an array even if the value is a set" do
      Set.mongoize(Set.new([ "test" ])).should eq([ "test" ])
    end
  end

  describe "#mongoize" do

    let(:set) do
      Set.new([ "test" ])
    end

    it "returns an array" do
      set.mongoize.should eq([ "test" ])
    end
  end
end
