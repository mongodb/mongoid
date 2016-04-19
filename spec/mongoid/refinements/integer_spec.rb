require "spec_helper"

describe Integer do
  using Mongoid::Refinements

  let(:number) do
    118347652312341
  end

  describe "#mongoize_time" do

    let(:integer) do
      1335532685
    end

    let(:mongoized) do
      integer.mongoize_time
    end

    it "returns the float as a time" do
      expect(mongoized).to eq(Time.at(integer))
    end
  end

  describe ".demongoize" do

    context "when the the value is an integer" do

      it "returns a integer" do
        expect(Integer.demongoize(number)).to eq(number)
      end
    end

    context "when the value is nil" do

      it "returns nil" do
        expect(Integer.demongoize(nil)).to be_nil
      end
    end

    context "when the value is not an integer" do

      it "converts the value to an integer" do
        expect(Integer.demongoize("1.0")).to eq(1)
      end
    end
  end

  describe ".mongoize" do

    context "when the value is a number" do

      context "when the value is an integer" do

        context "when the value is small" do

          it "it returns the integer" do
            expect(Integer.mongoize(3)).to eq(3)
          end
        end

        context "when the value is large" do

          it "returns the integer" do
            expect(Integer.mongoize(1024**2).to_s).to eq("1048576")
          end
        end
      end

      context "when the value is a decimal" do

        it "casts to integer" do
          expect(Integer.mongoize(2.5)).to eq(2)
        end
      end

      context "when the value is floating point zero" do

        it "returns the integer zero" do
          expect(Integer.mongoize(0.00000)).to eq(0)
        end
      end

      context "when the value is a floating point integer" do

        it "returns the integer number" do
          expect(Integer.mongoize(4.00000)).to eq(4)
        end
      end

      context "when the value has leading zeros" do

        it "returns the stripped integer" do
          expect(Integer.mongoize("000011")).to eq(11)
        end
      end
    end

    context "when the string is not a number" do

      context "when the string is non numerical" do

        it "returns 0" do
          expect(Integer.mongoize("foo")).to eq(0)
        end
      end

      context "when the string is numerical" do

        it "returns the integer value for the string" do
          expect(Integer.mongoize("3")).to eq(3)
        end
      end

      context "when the string is empty" do

        it "returns nil" do
          expect(Integer.mongoize("")).to be_nil
        end
      end

      context "when the string is nil" do

        it "returns nil" do
          expect(Integer.mongoize(nil)).to be_nil
        end
      end
    end
  end

  describe "#mongoize" do

    it "returns self" do
      expect(number.mongoize).to eq(number)
    end
  end

  describe ".evolve" do

    context "when provided a string" do

      context "when the string is a number" do

        context "when the string is an integer" do

          it "returns an integer" do
            expect(described_class.evolve("1")).to eq(1)
          end
        end

        context "when the string is a float" do

          it "converts it to a float" do
            expect(described_class.evolve("2.23")).to eq(2.23)
          end
        end

        context "when the string ends in ." do

          it "returns an integer" do
            expect(described_class.evolve("2.")).to eq(2)
          end
        end
      end

      context "when the string is not a number" do

        it "returns the string" do
          expect(described_class.evolve("testing")).to eq("testing")
        end
      end
    end
  end

  context "when provided a number" do

    context "when the number is an integer" do

      it "returns an integer" do
        expect(described_class.evolve(1)).to eq(1)
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
