require "spec_helper"

describe Mongoid::Extensions::Set do

  describe "#demongoize" do

    it "returns the set if Array" do
      expect(Set.demongoize([ "test" ])).to eq(Set.new([ "test" ]))
    end
  end

  describe ".mongoize" do

    it "returns an array" do
      expect(Set.mongoize([ "test" ])).to eq([ "test" ])
    end

    it "returns an array even if the value is a set" do
      expect(Set.mongoize(Set.new([ "test" ]))).to eq([ "test" ])
    end
  end

  describe "#mongoize" do

    let(:set) do
      Set.new([ "test" ])
    end

    it "returns an array" do
      expect(set.mongoize).to eq([ "test" ])
    end
  end
end
