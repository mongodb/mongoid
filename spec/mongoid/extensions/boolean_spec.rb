require "spec_helper"

describe Mongoid::Extensions::Boolean do

  describe ".demongoize" do

    context "when provided true" do

      it "returns true" do
        Boolean.demongoize(true).should eq(true)
      end
    end

    context "when provided false" do

      it "returns false" do
        Boolean.demongoize(false).should eq(false)
      end
    end
  end

  describe ".mongoize" do

    context "when provided a boolean" do

      context "when provided true" do

        it "returns true" do
          Boolean.mongoize(true).should eq(true)
        end
      end

      context "when provided false" do

        it "returns false" do
          Boolean.mongoize(false).should eq(false)
        end
      end
    end

    context "when provided a string" do

      context "when provided true" do

        it "returns true" do
          Boolean.mongoize("true").should eq(true)
        end
      end

      context "when provided t" do

        it "returns true" do
          Boolean.mongoize("t").should eq(true)
        end
      end

      context "when provided 1" do

        it "returns true" do
          Boolean.mongoize("1").should eq(true)
        end
      end

      context "when provided 1.0" do

        it "returns true" do
          Boolean.mongoize("1.0").should eq(true)
        end
      end

      context "when provided yes" do

        it "returns true" do
          Boolean.mongoize("yes").should eq(true)
        end
      end

      context "when provided y" do

        it "returns true" do
          Boolean.mongoize("y").should eq(true)
        end
      end

      context "when provided false" do

        it "returns false" do
          Boolean.mongoize("false").should eq(false)
        end
      end

      context "when provided f" do

        it "returns false" do
          Boolean.mongoize("f").should eq(false)
        end
      end

      context "when provided 0" do

        it "returns false" do
          Boolean.mongoize("0").should eq(false)
        end
      end

      context "when provided 0.0" do

        it "returns false" do
          Boolean.mongoize("0.0").should eq(false)
        end
      end

      context "when provided no" do

        it "returns false" do
          Boolean.mongoize("no").should eq(false)
        end
      end

      context "when provided n" do

        it "returns false" do
          Boolean.mongoize("n").should eq(false)
        end
      end
    end
  end

  describe "#mongoize" do

    it "returns self" do
      true.mongoize.should eq(true)
    end
  end
end
