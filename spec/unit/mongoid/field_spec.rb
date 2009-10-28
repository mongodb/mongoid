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

  describe "#type" do

    before do
      @field = Mongoid::Field.new(:name)
    end

    it "defaults to String" do
      @field.type.should == String
    end

  end

  describe "#value" do

    before do
      @type = mock
      @field = Mongoid::Field.new(:score, :default => 10, :type => @type)
    end

    context "nil is provided" do

      it "returns the default value" do
        @field.value(nil).should == 10
      end

    end

    context "value is provided" do

      it "casts the value" do
        @type.expects(:cast).with("30").returns(30)
        @field.value("30").should == 30
      end

    end

  end

end
