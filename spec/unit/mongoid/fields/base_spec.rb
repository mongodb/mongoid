require "spec_helper"

describe Mongoid::Fields::Base do

  describe "#cast_on_read?" do

    let(:field) do
      described_class.new(:test)
    end

    it "returns false" do
      field.should_not be_cast_on_read
    end
  end

  describe "#default" do

    context "when the default value is a proc" do

      let(:field) do
        described_class.new(:test, :default => lambda { 1 })
      end

      it "returns the called proc" do
        field.default.should == 1
      end
    end

    context "when the default value is not a proc" do

      let(:field) do
        described_class.new(:test, :default => "test")
      end

      it "returns the default value" do
        field.default.should == "test"
      end
    end
  end

  [ :deserialize, :get ].each do |method|

    let(:field) do
      described_class.new(:test)
    end

    describe "##{method}" do

      let(:value) do
        field.send(method, "testing")
      end

      it "returns the provided value" do
        value.should == "testing"
      end
    end
  end

  describe "#initialize" do

    let(:field) do
      described_class.new(:test, :type => Integer, :label => "test")
    end

    it "sets the name" do
      field.name.should == :test
    end

    it "sets the label" do
      field.label.should == "test"
    end

    it "sets the options" do
      field.options.should == { :type => Integer, :label => "test" }
    end

    context "when the default does not match the type" do

      it "raises an error" do
        expect {
          described_class.new(:test, :type => Integer, :default => "test")
        }.to raise_error(Mongoid::Errors::InvalidType)
      end
    end
  end

  describe ".option" do

    let(:options) do
      Mongoid::Field.options
    end

    let(:handler) do
      proc {}
    end

    it "stores the custom option in the options hash" do
      options.expects(:[]=).with(:option, handler)
      Mongoid::Field.option(:option, &handler)
    end
  end

  describe ".options" do

    it "returns a hash of custom options" do
      Mongoid::Field.options.should be_a Hash
    end

    it "is memoized" do
      Mongoid::Field.options.should equal(Mongoid::Field.options)
    end
  end

  [ :serialize, :set ].each do |method|

    let(:field) do
      described_class.new(:test)
    end

    describe "##{method}" do

      let(:value) do
        field.send(method, "testing")
      end

      it "returns the provided value" do
        value.should == "testing"
      end
    end
  end
end
