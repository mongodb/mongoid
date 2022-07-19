# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Extensions::Date do

  describe "__mongoize_time__" do

    context "when using active support's time zone" do
      include_context 'using AS time zone'

      let(:date) do
        Date.new(2010, 1, 1)
      end

      let(:expected_time) do
        Time.zone.local(2010, 1, 1, 0, 0, 0, 0)
      end

      let(:mongoized) do
        date.__mongoize_time__
      end

      it_behaves_like 'mongoizes to AS::TimeWithZone'
    end

    context "when not using active support's time zone" do
      include_context 'not using AS time zone'

      let(:date) do
        Date.new(2010, 1, 1)
      end

      let(:expected_time) do
        Time.local(2010, 1, 1, 0, 0, 0, 0)
      end

      let(:mongoized) do
        date.__mongoize_time__
      end

      it_behaves_like 'mongoizes to Time'
    end
  end

  describe ".demongoize" do

    let(:time) do
      Time.utc(2010, 1, 1, 0, 0, 0, 0)
    end

    let(:expected) do
      Date.new(2010, 1, 1)
    end

    it "keeps the date" do
      expect(Date.demongoize(expected)).to eq(expected)
      expect(Date.demongoize(expected)).to be_a(Date)
    end

    it "converts to a date" do
      expect(Date.demongoize(time)).to eq(expected)
      expect(Date.demongoize(time)).to be_a(Date)
    end

    context "when demongoizing nil" do

      it "returns nil" do
        expect(Date.demongoize(nil)).to be_nil
      end
    end

    context "when demongoizing a bogus value" do

      it "returns nil" do
        expect(Date.demongoize("bogus")).to be_nil
      end
    end

    context "when demongoizing a string" do

      let(:date) { "2022-07-11 14:03:42 -0400" }

      it "returns a date" do
        expect(Date.demongoize(date)).to eq(date.to_date)
      end
    end
  end

  describe "#mongoize" do

    let(:date) do
      Date.new(2010, 1, 1)
    end

    let(:time) do
      Time.utc(2010, 1, 1, 0, 0, 0, 0)
    end

    it "returns the date as a time at midnight" do
      expect(date.mongoize).to eq(time)
    end
  end

  describe ".mongoize" do
    let(:date) do
      Date.new(2010, 1, 1)
    end

    let(:time) do
      Time.utc(2010, 1, 1, 0, 0, 0, 0)
    end

    let(:datetime) do
      time.to_datetime
    end

    context "when the value is a date" do

      it "converts to a date" do
        expect(Date.mongoize(date)).to eq(date)
        expect(Date.mongoize(date)).to be_a(Time)
      end
    end

    context "when the value is a time" do

      it "keeps the time" do
        expect(Date.mongoize(time)).to eq(date)
        expect(Date.mongoize(time)).to be_a(Time)
      end
    end

    context "when the value is a datetime" do

      it "converts to a time" do
        expect(Date.mongoize(datetime)).to eq(date)
        expect(Date.mongoize(datetime)).to be_a(Time)
      end
    end

    context "when the value is uncastable" do

      it "returns nil" do
        expect(Date.mongoize("bogus")).to be_nil
      end
    end
  end
end
