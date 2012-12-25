require "spec_helper"

describe Mongoid::Boolean do

  describe ".demongoize" do

    context "when provided true" do

      it "returns true" do
        described_class.demongoize(true).should eq(true)
      end
    end

    context "when provided false" do

      it "returns false" do
        described_class.demongoize(false).should eq(false)
      end
    end
  end

  describe ".mongoize" do

    context "when provided a boolean" do

      context "when provided true" do

        it "returns true" do
          described_class.mongoize(true).should eq(true)
        end
      end

      context "when provided false" do

        it "returns false" do
          described_class.mongoize(false).should eq(false)
        end
      end
    end

    context "when provided a string" do

      context "when provided true" do

        it "returns true" do
          described_class.mongoize("true").should eq(true)
        end
      end

      context "when provided t" do

        it "returns true" do
          described_class.mongoize("t").should eq(true)
        end
      end

      context "when provided 1" do

        it "returns true" do
          described_class.mongoize("1").should eq(true)
        end
      end

      context "when provided 1.0" do

        it "returns true" do
          described_class.mongoize("1.0").should eq(true)
        end
      end

      context "when provided yes" do

        it "returns true" do
          described_class.mongoize("yes").should eq(true)
        end
      end

      context "when provided y" do

        it "returns true" do
          described_class.mongoize("y").should eq(true)
        end
      end

      context "when provided false" do

        it "returns false" do
          described_class.mongoize("false").should eq(false)
        end
      end

      context "when provided f" do

        it "returns false" do
          described_class.mongoize("f").should eq(false)
        end
      end

      context "when provided 0" do

        it "returns false" do
          described_class.mongoize("0").should eq(false)
        end
      end

      context "when provided 0.0" do

        it "returns false" do
          described_class.mongoize("0.0").should eq(false)
        end
      end

      context "when provided no" do

        it "returns false" do
          described_class.mongoize("no").should eq(false)
        end
      end

      context "when provided n" do

        it "returns false" do
          described_class.mongoize("n").should eq(false)
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
