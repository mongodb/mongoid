require "spec_helper"

describe Mongoid::Extensions::Nil::Collectionization do

  describe "#collectionize" do

    it "returns ''" do
      nil.collectionize.should == ""
    end
  end
end
