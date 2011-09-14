require "spec_helper"

describe Mongoid::Fields::Serializable::Array do

  let(:field) do
    described_class.instantiate(:test, :type => Array)
  end

  describe "#cast_on_read?" do

    it "returns false" do
      field.should_not be_cast_on_read
    end
  end

  describe "#eval_default" do

    context "when the default is a proc" do

      let(:field) do
        described_class.instantiate(
          :test,
          :type => Array,
          :default => lambda { [ "test" ] }
        )
      end

      it "calls the proc" do
        field.eval_default(nil).should == [ "test" ]
      end
    end

    context "when the default is an array" do

      let(:default) do
        [ "test" ]
      end

      let(:field) do
        described_class.instantiate(
          :test,
          :type => Array,
          :default => default
        )
      end

      it "returns the correct value" do
        field.eval_default(nil).should == default
      end

      it "returns a duped array" do
        field.eval_default(nil).should_not equal(default)
      end
    end
  end

  describe "#serialize" do

    context "when the value is not an array" do

      it "raises an error" do
        expect {
          field.serialize("test")
        }.to raise_error(Mongoid::Errors::InvalidType)
      end
    end

    context "when the value is nil" do

      it "returns nil" do
        field.serialize(nil).should be_nil
      end
    end

    context "when the value is an array" do

      it "returns the array" do
        field.serialize(["test"]).should == ["test"]
      end
    end
  end
end
