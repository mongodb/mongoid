require "spec_helper"

describe Mongoid::Field do

  describe "#accessible?" do

    context "when value is not set" do

      before do
        @field = Mongoid::Field.new(:name)
      end

      it "defaults to true" do
        @field.accessible?.should be_true
      end
    end

    context "when set to true" do

      before do
        @field = Mongoid::Field.new(:name, :accessible => true)
      end

      it "returns true" do
        @field.accessible?.should be_true
      end
    end

    context "when set to false" do

      before do
        @field = Mongoid::Field.new(:name, :accessible => false)
      end

      it "returns false" do
        @field.accessible?.should be_false
      end
    end
  end

  describe "#default" do

    before do
      @field = Mongoid::Field.new(:score, :type => Integer, :default => 0)
    end

    it "returns the default option" do
      @field.default.should == 0
    end

    context "when the field is an array" do

      before do
        @field = Mongoid::Field.new(:vals, :type => Array, :default => [ "first" ])
      end

      it "dups the array" do
        array = @field.default
        array << "second"
        @field.default.should == [ "first" ]
      end
    end

    context "when the field is a hash" do

      before do
        @field = Mongoid::Field.new(:vals, :type => Hash, :default => { :key => "value" })
      end

      it "dups the hash" do
        hash = @field.default
        hash[:key_two] = "value2"
        @field.default.should == { :key => "value" }
      end
    end

  end

  describe "#initialize" do

    context "when the field name is invalid" do

      it "raises an error" do
        lambda { Mongoid::Field.new(:collection) }.should raise_error(Mongoid::Errors::InvalidField)
      end
    end

    context "when the default value does not match the type" do

      it "raises an error" do
        lambda {
          Mongoid::Field.new(:names, :type => Integer, :default => "Jacob")
        }.should raise_error(Mongoid::Errors::InvalidType)
      end
    end
  end

  describe "#name" do

    before do
      @field = Mongoid::Field.new(:score, :type => Integer, :default => 0)
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
      @field = Mongoid::Field.new(:score, :default => 10, :type => Integer)
    end

    context "nil is provided" do

      it "returns the default value" do
        @field.set(nil).should == nil
      end

    end

    context "value is provided" do

      it "sets the value" do
        @field.set("30").should == 30
      end

    end

  end

  describe "#get" do

    before do
      @field = Mongoid::Field.new(:score, :default => 10, :type => Integer)
    end

    it "returns the value" do
      @field.get(30).should == 30
    end
  end

  describe "#options" do
    before do
      @field = Mongoid::Field.new(:terrible_and_unsafe_html_goes_here, :sanitize => true, :hello => :goodbye)
    end

    it "stores the arbitrary options" do
      @field.options[:sanitize].should be_true
      @field.options[:hello].should == :goodbye
    end

  end

end
