require "spec_helper"

describe Mongoid::Fields::Internal::String do

  let(:field) do
    described_class.instantiate(:test, :type => String, :vresioned => true)
  end

  describe "#deserialize" do

    it "returns the string" do
      field.deserialize("test").should == "test"
    end
  end

  describe "#foreign_key?" do

    it "returns false" do
      field.should_not be_foreign_key
    end
  end

  describe "#selection" do

    context "when providing a single value" do

      it "converts the value to a string" do
        field.selection(:test).should eq("test")
      end
    end

    context "when providing a complex criteria" do

      let(:criteria) do
        { "$ne" => "test" }
      end

      it "returns the criteria" do
        field.selection(criteria).should eq(criteria)
      end
    end
  end

  describe "#serialize" do

    context "when the value is not nil" do

      it "returns the object to_s" do
        field.serialize(1).should == "1"
      end
    end

    context "when the value is nil" do

      it "returns nil" do
        field.serialize(nil).should be_nil
      end
    end
  end

  describe "localized?" do

    context "when the field is localized" do

      let(:field) do
        described_class.instantiate(:test, :type => String, :localize => true)
      end

      it "returns true" do
        field.should be_localized
      end
    end

    context "when the field is not localized" do

      it "returns false" do
        field.should_not be_localized
      end
    end
  end

  describe "#versioned?" do

    context "when the field is versioned" do

      let(:field) do
        described_class.instantiate(:test, :type => String, :versioned => true)
      end

      it "returns true" do
        field.should be_versioned
      end
    end

    context "when the versioning option is nil" do

      let(:field) do
        described_class.instantiate(:test, :type => String)
      end

      it "returns true" do
        field.should be_versioned
      end
    end

    context "when the field is not versioned" do

      let(:field) do
        described_class.instantiate(:test, :type => String, :versioned => false)
      end

      it "returns false" do
        field.should_not be_versioned
      end
    end
  end
end
