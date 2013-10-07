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
      expect(mongoized).to eq(Time.at(float))
    end
  end

  describe ".demongoize" do

    context "when the the value is a float" do

      it "returns a float" do
        expect(Float.demongoize(number)).to eq(number)
      end
    end

    context "when the value is nil" do

      it "returns nil" do
        expect(Float.demongoize(nil)).to be_nil
      end
    end

    context "when the value is a float string" do

      it "returns a float" do
        expect(Float.demongoize(number.to_s)).to eq(number)
      end
    end

    context "when the value is not a float string" do

      it "returns a float" do
        expect(Float.demongoize('asdf')).to eq(0)
      end
    end
  end

  describe ".mongoize" do

    context "when the value is a number" do

      context "when the value is an float" do

        context "when the value is small" do

          it "it returns the float" do
            expect(Float.mongoize(3)).to eq(3)
          end

          it "returns the number as type float" do
            expect(Float.mongoize(3)).to be_a(Float)
          end
        end

        context "when the value is large" do

          it "returns the float" do
            expect(Float.mongoize(1024**2).to_s).to eq("1048576.0")
          end
        end
      end

      context "when the value is a decimal" do

        it "casts to float" do
          expect(Float.mongoize(2.5)).to eq(2.5)
        end
      end

      context "when the value is floating point zero" do

        it "returns the float zero" do
          expect(Float.mongoize(0.00000)).to eq(0)
        end
      end

      context "when the value is a floating point float" do

        it "returns the float number" do
          expect(Float.mongoize(4.00000)).to eq(4)
        end
      end

      context "when the value has leading zeros" do

        it "returns the stripped float" do
          expect(Float.mongoize("000011")).to eq(11)
        end
      end
    end

    context "when the string is not a number" do

      context "when the string is non numerical" do

        it "returns 0" do
          expect(Float.mongoize("foo")).to eq(0.0)
        end
      end

      context "when the string is numerical" do

        it "returns the float value for the string" do
          expect(Float.mongoize("3")).to eq(3)
        end
      end

      context "when the string is empty" do

        it "returns nil" do
          expect(Float.mongoize("")).to be_nil
        end
      end

      context "when the string is nil" do

        it "returns nil" do
          expect(Float.mongoize(nil)).to be_nil
        end
      end
    end
  end

  describe "#mongoize" do

    it "returns self" do
      expect(number.mongoize).to eq(number)
    end
  end
end
