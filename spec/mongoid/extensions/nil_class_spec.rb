require "spec_helper"

describe Mongoid::Extensions::NilClass do

  describe "#collectionize" do

    it "returns ''" do
      nil.collectionize.should eq("")
    end
  end
end
