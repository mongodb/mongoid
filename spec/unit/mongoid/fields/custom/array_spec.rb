require "spec_helper"

describe Mongoid::Fields::Custom::Array do

  let(:field) do
    described_class.new(:test, :type => Array)
  end

  describe "#cast_on_read?" do

    it "returns false" do
      field.should_not be_cast_on_read
    end
  end

  describe "#default" do

    context "when the default is a proc" do

      let(:field) do
        described_class.new(
          :test,
          :type => Array,
          :default => lambda { [ "test" ] }
        )
      end

      it "calls the proc" do
        field.default.should == [ "test" ]
      end
    end

    context "when the default is an array" do

      let(:default) do
        [ "test" ]
      end

      let(:field) do
        described_class.new(
          :test,
          :type => Array,
          :default => default
        )
      end

      it "returns the correct value" do
        field.default.should == default
      end

      it "returns a duped array" do
        field.default.should_not equal(default)
      end
    end
  end

  [ :deserialize, :get ].each do |method|

    describe "##{method}" do

      context "when the value is not an array" do

        it "raises an error" do
          expect {
            field.send(method, "test")
          }.to raise_error(Mongoid::Errors::InvalidType)
        end
      end

      context "when the value is nil" do

        it "returns nil" do
          field.send(method, nil).should be_nil
        end
      end

      context "when the value is an array" do

        it "returns the array" do
          field.send(method, ["test"]).should == ["test"]
        end
      end
    end
  end

  [ :serialize, :set ].each do |method|

    describe "##{method}" do

      context "when the value is not an array" do

        it "raises an error" do
          expect {
            field.send(method, "test")
          }.to raise_error(Mongoid::Errors::InvalidType)
        end
      end

      context "when the value is nil" do

        it "returns nil" do
          field.send(method, nil).should be_nil
        end
      end

      context "when the value is an array" do

        it "returns the array" do
          field.send(method, ["test"]).should == ["test"]
        end
      end
    end
  end
end
