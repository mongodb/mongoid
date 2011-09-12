require "spec_helper"

describe Mongoid::Fields::Serializable::BigDecimal do

  let(:field) do
    described_class.instantiate(:test, :type => BigDecimal)
  end

  let(:number) do
    BigDecimal.new("123456.789")
  end

  describe "#cast_on_read?" do

    it "returns true" do
      field.should be_cast_on_read
    end
  end

  describe "#deserialize" do

    context "when the the value is a string" do

      it "returns a big decimal" do
        field.deserialize(number.to_s).should == number
      end
    end

    context "when the value is nil" do

      it "returns nil" do
        field.deserialize(nil).should be_nil
      end
    end
  end

  describe "#serialize" do

    context "when the value is a big decimal" do

      it "returns a string" do
        field.serialize(number).should == number.to_s
      end
    end

    context "when the value is nil" do

      it "returns nil" do
        field.serialize(nil).should be_nil
      end
    end
  end
end
