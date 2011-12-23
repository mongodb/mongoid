require "spec_helper"

describe Mongoid::Fields::Internal::Range do

  let(:field) do
    described_class.instantiate(:test, :type => Range)
  end

  describe "#cast_on_read?" do

    it "returns true" do
      field.should be_cast_on_read
    end
  end

  describe "#deserialize" do

    it "returns a range" do
      field.deserialize({"min" => 1, "max" => 3}).should == (1..3)
    end

    it "returns an inverse range" do
      field.deserialize({"min" => 5, "max" => 1}).should == (5..1)
    end

    it "returns a letter range" do
      field.deserialize({"min" => 'a', "max" => 'z'}).should == ('a'..'z')
    end
  end

  describe "#selection" do

    context "when providing a single value" do

      it "converts to a range query" do
        field.selection(1..3).should eq(
          { "min" => { "$gte" => 1 }, "max" => { "$lte" => 3 }}
        )
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

      it "returns the object hash" do
        field.serialize(1..3).should == {"min" => 1, "max" => 3}
      end

      it "returns the object hash when passed an inverse range" do
        field.serialize(5..1).should == {"min" => 5, "max" => 1}
      end

      it "returns the object hash when passed a letter range" do
        field.serialize('a'..'z').should == {"min" => 'a', "max" => 'z'}
      end
    end

    context "when the value is nil" do

      it "returns nil" do
        field.serialize(nil).should be_nil
      end
    end
  end
end
