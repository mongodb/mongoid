require "spec_helper"

describe Mongoid::Extensions::Hash::Conversions do

  describe "#get" do

    it "returns the hash" do
      Hash.get({ :field => "test" }).should == { :field => "test" }
    end

  end

  describe "#set" do

    it "returns the hash" do
      Hash.set({ :field => "test" }).should == { :field => "test" }
    end

  end

end
