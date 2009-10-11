require File.join(File.dirname(__FILE__), "/../../spec_helper.rb")

describe Mongoid::Field do

  describe "#default" do

    before do
      @field = Mongoid::Field.new(:score, :default => 0)
    end

    it "returns the default option" do
      @field.default.should == 0
    end

  end

  describe "#name" do

    before do
      @field = Mongoid::Field.new(:score, :default => 0)
    end

    it "returns the name" do
      @field.name.should == :score
    end

  end

end
