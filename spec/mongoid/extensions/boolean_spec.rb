require "spec_helper"

describe Mongoid::Boolean do

  describe ".demongoize" do

    context "when provided true" do

      it "returns true" do
        expect(described_class.demongoize(true)).to eq(true)
      end
    end

    context "when provided false" do

      it "returns false" do
        expect(described_class.demongoize(false)).to eq(false)
      end
    end
  end

  describe ".mongoize" do

    context "when provided a boolean" do

      context "when provided true" do

        it "returns true" do
          expect(described_class.mongoize(true)).to eq(true)
        end
      end

      context "when provided false" do

        it "returns false" do
          expect(described_class.mongoize(false)).to eq(false)
        end
      end
    end

    context "when provided a string" do

      context "when provided true" do

        it "returns true" do
          expect(described_class.mongoize("true")).to eq(true)
        end
      end

      context "when provided t" do

        it "returns true" do
          expect(described_class.mongoize("t")).to eq(true)
        end
      end

      context "when provided 1" do

        it "returns true" do
          expect(described_class.mongoize("1")).to eq(true)
        end
      end

      context "when provided 1.0" do

        it "returns true" do
          expect(described_class.mongoize("1.0")).to eq(true)
        end
      end

      context "when provided yes" do

        it "returns true" do
          expect(described_class.mongoize("yes")).to eq(true)
        end
      end

      context "when provided y" do

        it "returns true" do
          expect(described_class.mongoize("y")).to eq(true)
        end
      end

      context "when provided false" do

        it "returns false" do
          expect(described_class.mongoize("false")).to eq(false)
        end
      end

      context "when provided f" do

        it "returns false" do
          expect(described_class.mongoize("f")).to eq(false)
        end
      end

      context "when provided 0" do

        it "returns false" do
          expect(described_class.mongoize("0")).to eq(false)
        end
      end

      context "when provided 0.0" do

        it "returns false" do
          expect(described_class.mongoize("0.0")).to eq(false)
        end
      end

      context "when provided no" do

        it "returns false" do
          expect(described_class.mongoize("no")).to eq(false)
        end
      end

      context "when provided n" do

        it "returns false" do
          expect(described_class.mongoize("n")).to eq(false)
        end
      end
    end
  end

  describe "#mongoize" do

    it "returns self" do
      expect(true.mongoize).to eq(true)
    end
  end
end
