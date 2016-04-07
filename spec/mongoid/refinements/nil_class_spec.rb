require "spec_helper"

describe Mongoid::Refinements do
  using Mongoid::Refinements

  describe "#collectionize" do

    it "returns ''" do
      expect(nil.collectionize).to be_empty
    end
  end
end
