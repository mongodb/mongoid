require "spec_helper"

describe Mongoid::Extensions::Boolean do

  describe ".demongoize" do

    context "when provided true" do

      it "returns true" do
        expect(Boolean.demongoize(true)).to eq(true)
      end
    end

    context "when provided false" do

      it "returns false" do
        expect(Boolean.demongoize(false)).to eq(false)
      end
    end
  end

  describe ".mongoize" do

    context "when provided a boolean" do

      context "when provided true" do

        it "returns true" do
          expect(Boolean.mongoize(true)).to eq(true)
        end
      end

      context "when provided false" do

        it "returns false" do
          expect(Boolean.mongoize(false)).to eq(false)
        end
      end
    end

    context "when provided a string" do

      context "when provided true" do

        it "returns true" do
          expect(Boolean.mongoize("true")).to eq(true)
        end
      end

      context "when provided t" do

        it "returns true" do
          expect(Boolean.mongoize("t")).to eq(true)
        end
      end

      context "when provided 1" do

        it "returns true" do
          expect(Boolean.mongoize("1")).to eq(true)
        end
      end

      context "when provided 1.0" do

        it "returns true" do
          expect(Boolean.mongoize("1.0")).to eq(true)
        end
      end

      context "when provided yes" do

        it "returns true" do
          expect(Boolean.mongoize("yes")).to eq(true)
        end
      end

      context "when provided y" do

        it "returns true" do
          expect(Boolean.mongoize("y")).to eq(true)
        end
      end

      context "when provided false" do

        it "returns false" do
          expect(Boolean.mongoize("false")).to eq(false)
        end
      end

      context "when provided f" do

        it "returns false" do
          expect(Boolean.mongoize("f")).to eq(false)
        end
      end

      context "when provided 0" do

        it "returns false" do
          expect(Boolean.mongoize("0")).to eq(false)
        end
      end

      context "when provided 0.0" do

        it "returns false" do
          expect(Boolean.mongoize("0.0")).to eq(false)
        end
      end

      context "when provided no" do

        it "returns false" do
          expect(Boolean.mongoize("no")).to eq(false)
        end
      end

      context "when provided n" do

        it "returns false" do
          expect(Boolean.mongoize("n")).to eq(false)
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
