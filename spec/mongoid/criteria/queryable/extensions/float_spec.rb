require "spec_helper"

describe Float do

  describe ".evolve" do

    context "when provided a string" do

      context "when the string is a number" do

        context "when the string is an integer" do

          it "returns a float" do
            expect(described_class.evolve("1")).to eq(1.0)
          end
        end

        context "when the string is a float" do

          it "converts it to a float" do
            expect(described_class.evolve("2.23")).to eq(2.23)
          end
        end
      end

      context "when the string is not a number" do

        it "returns the string" do
          expect(described_class.evolve("testing")).to eq("testing")
        end
      end
    end

    context "when provided an array of strings" do

      it "returns the array of floats" do
        expect(described_class.evolve([ "2.23" ])).to eq([ 2.23 ])
      end
    end

    context "when provided a number" do

      context "when the number is an integer" do

        it "returns a float" do
          expect(described_class.evolve(1)).to eq(1.0)
        end
      end

      context "when the number is a float" do

        it "returns the float" do
          expect(described_class.evolve(2.23)).to eq(2.23)
        end
      end
    end

    context "when provided nil" do

      it "returns nil" do
        expect(described_class.evolve(nil)).to be_nil
      end
    end
  end
end
