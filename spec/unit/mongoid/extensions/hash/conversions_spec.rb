require File.expand_path(File.join(File.dirname(__FILE__), "/../../../../spec_helper.rb"))

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
