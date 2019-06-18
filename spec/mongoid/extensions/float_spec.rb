# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Extensions::Float do

  let(:number) do
    118.345
  end

  describe "#__mongoize_time__" do

    let(:float) do
      1335532685.123457
    end

    let(:mongoized) do
      float.__mongoize_time__
    end

    let(:expected_time) { Time.at(float).in_time_zone }

    context "when using active support's time zone" do
      include_context 'using AS time zone'

      it_behaves_like 'mongoizes to AS::TimeWithZone'
      it_behaves_like 'maintains precision when mongoized'
    end

    context "when not using active support's time zone" do
      include_context 'not using AS time zone'

      it_behaves_like 'mongoizes to Time'
      it_behaves_like 'maintains precision when mongoized'
    end
  end

  describe ".demongoize" do

    context "when the value is a float" do

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

  describe "#numeric?" do

    it "returns true" do
      expect(number.numeric?).to eq(true)
    end
  end
end
