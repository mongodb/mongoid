require "spec_helper"

[::Boolean, Mongoid::Boolean].each do |_class|
  using Mongoid::Refinements

  describe _class do

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

    describe ".evolve" do

      context "when provided a boolean" do

        context "when provided true" do

          it "returns true" do
            expect(described_class.evolve(true)).to eq(true)
          end
        end

        context "when provided false" do

          it "returns false" do
            expect(described_class.evolve(false)).to eq(false)
          end
        end
      end

      context "when provided a string" do

        context "when provided true" do

          it "returns true" do
            expect(described_class.evolve("true")).to eq(true)
          end
        end

        context "when provided t" do

          it "returns true" do
            expect(described_class.evolve("t")).to eq(true)
          end
        end

        context "when provided 1" do

          it "returns true" do
            expect(described_class.evolve("1")).to eq(true)
          end
        end

        context "when provided 1.0" do

          it "returns true" do
            expect(described_class.evolve("1.0")).to eq(true)
          end
        end

        context "when provided yes" do

          it "returns true" do
            expect(described_class.evolve("yes")).to eq(true)
          end
        end

        context "when provided y" do

          it "returns true" do
            expect(described_class.evolve("y")).to eq(true)
          end
        end

        context "when provided false" do

          it "returns false" do
            expect(described_class.evolve("false")).to eq(false)
          end
        end

        context "when provided f" do

          it "returns false" do
            expect(described_class.evolve("f")).to eq(false)
          end
        end

        context "when provided 0" do

          it "returns false" do
            expect(described_class.evolve("0")).to eq(false)
          end
        end

        context "when provided 0.0" do

          it "returns false" do
            expect(described_class.evolve("0.0")).to eq(false)
          end
        end

        context "when provided no" do

          it "returns false" do
            expect(described_class.evolve("no")).to eq(false)
          end
        end

        context "when provided n" do

          it "returns false" do
            expect(described_class.evolve("n")).to eq(false)
          end
        end
      end
    end

    context "when provided an array" do

      context "when provided a string" do

        context "when provided true" do

          let(:array) do
            [ "true" ]
          end

          let(:evolved) do
            described_class.evolve(array)
          end

          it "returns true" do
            expect(evolved).to eq([ true ])
          end

          it "does not evolve in place" do
            expect(evolved).to_not equal(array)
          end
        end

        context "when provided t" do

          it "returns true" do
            expect(described_class.evolve([ "t" ])).to eq([ true ])
          end
        end

        context "when provided 1" do

          it "returns true" do
            expect(described_class.evolve([ "1" ])).to eq([ true ])
          end
        end

        context "when provided 1.0" do

          it "returns true" do
            expect(described_class.evolve([ "1.0" ])).to eq([ true ])
          end
        end

        context "when provided yes" do

          it "returns true" do
            expect(described_class.evolve([ "yes" ])).to eq([ true ])
          end
        end

        context "when provided y" do

          it "returns true" do
            expect(described_class.evolve([ "y" ])).to eq([ true ])
          end
        end

        context "when provided false" do

          it "returns false" do
            expect(described_class.evolve([ "false" ])).to eq([ false ])
          end
        end

        context "when provided f" do

          it "returns false" do
            expect(described_class.evolve([ "f" ])).to eq([ false ])
          end
        end

        context "when provided 0" do

          it "returns false" do
            expect(described_class.evolve([ "0" ])).to eq([ false ])
          end
        end

        context "when provided 0.0" do

          it "returns false" do
            expect(described_class.evolve([ "0.0" ])).to eq([ false ])
          end
        end

        context "when provided no" do

          it "returns false" do
            expect(described_class.evolve([ "no" ])).to eq([ false ])
          end
        end

        context "when provided n" do

          it "returns false" do
            expect(described_class.evolve([ "n" ])).to eq([ false ])
          end
        end
      end
    end
  end
end
