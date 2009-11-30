require "spec_helper"

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

  describe "#set" do

    before do
      @type = mock
      @field = Mongoid::Field.new(:score, :default => 10, :type => @type)
    end

    context "nil is provided" do

      it "returns the default value" do
        @field.set(nil).should == 10
      end

    end

    context "value is provided" do

      it "sets the value" do
        @type.expects(:set).with("30").returns(30)
        @field.set("30").should == 30
      end

    end

  end

  describe "#get" do

    before do
      @type = mock
      @field = Mongoid::Field.new(:score, :default => 10, :type => @type)
    end

    it "returns the value" do
      @type.expects(:get).with(30).returns(30)
      @field.get(30).should == 30
    end

  end

end
