require "spec_helper"

describe Mongoid::Extensions::Float do

  let(:number) do
    118.345
  end

  describe "#__mongoize_time__" do

    let(:float) do
      1335532685.117847
    end

    let(:mongoized) do
      float.__mongoize_time__
    end

    it "returns the float as a time" do
      mongoized.should eq(Time.at(float))
    end
  end

  describe ".demongoize" do

    context "when the the value is a float" do

      it "returns a float" do
        Float.demongoize(number).should eq(number)
      end
    end

    context "when the value is nil" do

      it "returns nil" do
        Float.demongoize(nil).should be_nil
      end
    end
  end

  describe ".mongoize" do

    context "when the value is a number" do

      context "when the value is an float" do

        context "when the value is small" do

          it "it returns the float" do
            Float.mongoize(3).should eq(3)
          end

          it "returns the number as type float" do
            Float.mongoize(3).should be_a(Float)
          end
        end

        context "when the value is large" do

          it "returns the float" do
            Float.mongoize(1024**2).to_s.should eq("1048576.0")
          end
        end
      end

      context "when the value is a decimal" do

        it "casts to float" do
          Float.mongoize(2.5).should eq(2.5)
        end
      end

      context "when the value is floating point zero" do

        it "returns the float zero" do
          Float.mongoize(0.00000).should eq(0)
        end
      end

      context "when the value is a floating point float" do

        it "returns the float number" do
          Float.mongoize(4.00000).should eq(4)
        end
      end

      context "when the value has leading zeros" do

        it "returns the stripped float" do
          Float.mongoize("000011").should eq(11)
        end
      end
    end

    context "when the string is not a number" do

      context "when the string is non numerical" do

        it "returns 0" do
          Float.mongoize("foo").should eq(0.0)
        end
      end

      context "when the string is numerical" do

        it "returns the float value for the string" do
          Float.mongoize("3").should eq(3)
        end
      end

      context "when the string is empty" do

        it "returns nil" do
          Float.mongoize("").should be_nil
        end
      end

      context "when the string is nil" do

        it "returns nil" do
          Float.mongoize(nil).should be_nil
        end
      end
    end
  end

  describe "#mongoize" do

    it "returns self" do
      number.mongoize.should eq(number)
    end
  end
end
