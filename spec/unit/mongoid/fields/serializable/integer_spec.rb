require "spec_helper"

describe Mongoid::Fields::Serializable::Integer do

  let(:field) do
    described_class.instantiate(:test, :type => Integer)
  end

  describe "#deserialize" do

    it "returns the integer" do
      field.deserialize(3).should == 3
    end
  end

  describe "#serialize" do

    context "when the value is a number" do

      context "when the value is an integer" do

        context "when the value is small" do

          it "it returns the integer" do
            field.serialize(3).should == 3
          end
        end

        context "when the value is large" do

          it "returns the integer" do
            field.serialize(1024**2).to_s.should eq("1048576")
          end
        end
      end

      context "when the value is a decimal" do

        it "returns the decimal" do
          field.serialize(2.5).should == 2.5
        end
      end

      context "when the value is floating point zero" do

        it "returns the integer zero" do
          field.serialize(0.00000).should eq(0)
        end
      end

      context "when the value is a floating point integer" do

        it "returns the integer number" do
          field.serialize(4.00000).should eq(4)
        end
      end

      context "when the value has leading zeros" do

        it "returns the stripped integer" do
          field.serialize("000011").should eq(11)
        end
      end
    end

    context "when the string is not a number" do

      context "when the string is non numerical" do

        it "returns the string" do
          field.serialize("foo").should == "foo"
        end
      end

      context "when the string is numerical" do

        it "returns the integer value for the string" do
          field.serialize("3").should == 3
        end
      end

      context "when the string is empty" do

        it "returns an empty string" do
          field.serialize("").should be_nil
        end
      end

      context "when the string is nil" do

        it "returns nil" do
          field.serialize(nil).should be_nil
        end
      end
    end
  end
end
