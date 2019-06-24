# frozen_string_literal: true
# encoding: utf-8

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
      expect(Date.demongoize(time)).to eq(expected)
    end

    it "converts to a date" do
      expect(Date.demongoize(time)).to be_a(Date)
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
end
