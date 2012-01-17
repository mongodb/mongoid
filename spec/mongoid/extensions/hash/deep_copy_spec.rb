require "spec_helper"

describe Mongoid::Extensions::Object::DeepCopy do

  describe "#_deep_copy" do

    let(:value) do
      { :key => "value" }
    end

    let(:hash) do
      { :test => value }
    end

    let(:copy) do
      hash._deep_copy
    end

    it "returns an equal object" do
      copy.should eq(hash)
    end

    it "returns a new instance" do
      copy.should_not equal(hash)
    end

    it "clones nested values" do
      copy[:test].should_not equal(value)
    end
  end
end
