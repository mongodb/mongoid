require "spec_helper"

describe Mongoid::Extensions::Hash::Conversions do

  describe ".try_bson" do

    it "returns the hash" do
      Hash.try_bson({ :field => "test" }).should == { :field => "test" }
    end

  end

  describe ".from_bson" do

    it "returns the hash" do
      Hash.from_bson({ :field => "test" }).should == { :field => "test" }
    end
  end
end
