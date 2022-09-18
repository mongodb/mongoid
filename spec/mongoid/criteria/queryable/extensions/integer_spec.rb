# frozen_string_literal: true

require "spec_helper"

describe Integer do

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

  describe "#__evolve_time__" do

    context 'UTC time zone' do
      let(:time) do
        Time.parse("2022-01-01 16:15:01 UTC")
      end

      let(:evolved) do
        time.to_i.__evolve_time__
      end

      it 'evolves the correct time' do
        expect(evolved).to eq(time)
      end
    end

    context 'other time zone' do
      let(:time) do
        Time.parse("2022-01-01 16:15:01 +0900")
      end

      let(:evolved) do
        time.to_i.__evolve_time__
      end

      it 'evolves the correct time' do
        expect(evolved).to eq(time)
      end
    end
  end

  describe "#__evolve_date__" do

    context 'exact match' do
      let(:date) do
        Date.parse("2022-01-01")
      end

      let(:evolved) do
        Time.parse("2022-01-01 0:00 UTC").to_i.__evolve_date__
      end

      it 'evolves the correct time' do
        expect(evolved).to eq(date)
      end
    end

    context 'one second earlier' do
      let(:date) do
        Date.parse("2021-12-31")
      end

      let(:evolved) do
        (Time.parse("2022-01-01 0:00 UTC").to_i - 1).__evolve_date__
      end

      it 'evolves the correct time' do
        expect(evolved).to eq(date)
      end
    end

    context 'one second later' do
      let(:date) do
        Date.parse("2022-01-01")
      end

      let(:evolved) do
        (Time.parse("2022-01-01 0:00 UTC").to_i + 1).__evolve_date__
      end

      it 'evolves the correct time' do
        expect(evolved).to eq(date)
      end
    end
  end
end
