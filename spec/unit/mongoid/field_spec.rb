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

  describe "#key?" do

    context "when key option provided" do
      before do
        @field = Mongoid::Field.new(:title, :key => true)
      end

      it "returns true" do
        @field.key?.should be_true
      end
    end
    
    context "when key option not provided" do
      before do
        @field = Mongoid::Field.new(:title)
      end
      
      it "returns false" do
        @field.key?.should be_false
      end
    end

  end

end