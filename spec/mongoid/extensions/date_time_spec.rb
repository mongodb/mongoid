# frozen_string_literal: true
# encoding: utf-8

require "spec_helper"

describe Mongoid::Extensions::DateTime do

  describe "__mongoize_time__" do

    let(:date_time) do
      # DateTime has time zone information, even if a time zone is not provided
      # when parsing a string
      DateTime.parse("2012-06-17 18:42:15.123457")
    end

    let(:mongoized) do
      date_time.__mongoize_time__
    end

    let(:expected_time) { date_time.to_time.in_time_zone }

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

    let!(:time) do
      Time.now.utc
    end

    let(:date_time) do
      DateTime.demongoize(time)
    end

    it "converts to a datetime" do
      expect(date_time).to be_kind_of(DateTime)
    end

    it "does not change the time" do
      expect(DateTime.demongoize(time)).to eq(time)
    end

    context "when using utc" do

      before do
        Mongoid.use_utc = true
      end

      after do
        Mongoid.use_utc = false
      end

      context "when setting a utc time" do

        let(:user) do
          User.new
        end

        let(:date) do
          DateTime.parse("2012-01-23 08:26:14 PM")
        end

        before do
          user.last_login = date
        end

        it "does not return the time with time zone applied" do
          expect(user.last_login).to eq(date)
        end
      end
    end
  end

  describe ".mongoize" do

    context "when the string is an invalid time" do

      it "returns nil" do
        expect(DateTime.mongoize("time")).to eq(nil)
      end
    end
  end

  describe "#mongoize" do

    let!(:date_time) do
      Time.now.utc.to_datetime
    end

    context "when the string is an invalid time" do

      it "returns the date time as a time" do
        expect(date_time.mongoize).to be_a(Time)
      end
    end
  end
end
