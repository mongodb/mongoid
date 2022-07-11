# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Extensions::Date do

  describe ".mongoize" do

    context "when provided a date" do

      let(:date) do
        Date.new(2010, 1, 1)
      end

      let(:mongoized) do
        Date.mongoize(date)
      end

      let(:expected) do
        Time.utc(2010, 1, 1, 0, 0, 0)
      end

      it "returns the time" do
        expect(mongoized).to eq(expected)
      end
    end

    context "when provided a string" do
      # This also configures a non-UTC time zone for AS which we want
      include_context 'using AS time zone'

      context "when the string is a valid date" do

        let(:mongoized) do
          Date.mongoize('2010-01-01')
        end

        let(:expected) do
          # Date is always serialized as UTC time with zero time component
          # on the specified date, regardless of time zone.
          # This allows the application to change its time zone and
          # retrieve the date back unchanged.
          Time.utc(2010, 1, 1, 0, 0, 0, 0)
        end

        it "returns the beginning of date in UTC" do
          expect(mongoized).to eq(expected)
        end
      end

      context "when the string is a valid date and time" do

        let(:mongoized) do
          Date.mongoize("2010-01-01 02:00:00")
        end

        let(:expected) do
          # Time component is ignored, date is specified in UTC
          Time.utc(2010, 1, 1, 0, 0, 0, 0)
        end

        it "returns beginning of date in UTC" do
          expect(mongoized).to eq(expected)
        end
      end

      context "when the string is a valid date and time in later time zone" do

        let(:mongoized) do
          # Tokyo is +9
          Date.mongoize("2010-01-01 00:00:00 +1000")
        end

        let(:expected) do
          Time.utc(2010, 1, 1, 0, 0, 0, 0)
        end

        it "returns the date specified in the string without regard for local day" do
          expect(mongoized).to eq(expected)
        end
      end

      context "when the string is a valid date and time in earlier time zone" do

        let(:mongoized) do
          # Tokyo is +9
          Date.mongoize("2010-01-01 20:00:00 +0400")
        end

        let(:expected) do
          Time.utc(2010, 1, 1, 0, 0, 0, 0)
        end

        it "returns the date specified in the string without regard for local day" do
          expect(mongoized).to eq(expected)
        end
      end

      context "when the string is empty" do

        let(:mongoized) do
          Date.mongoize("")
        end

        it "returns nil" do
          expect(mongoized).to be_nil
        end
      end

      context "when the string is an invalid time" do

        let(:mongoized) do
          Date.mongoize("time")
        end

        it "returns nil" do
          expect(mongoized).to be_nil
        end
      end
    end

    context "when provided a float" do
      include_context 'using AS time zone'

      let(:float) do
        time.to_f
      end

      let(:mongoized) do
        Date.mongoize(float)
      end

      context 'float in the same local day' do
        let(:time) do
          Time.utc(2010, 1, 1, 2, 3, 4, 123456)
        end

        let(:expected) do
          Time.utc(2010, 1, 1, 0, 0, 0, 0)
        end

        it "returns start of the day as date" do
          expect(mongoized).to eq(expected)
        end
      end

      context 'float in a different local day' do
        let(:time) do
          Time.utc(2010, 1, 1, 22, 3, 4, 123456)
        end

        let(:expected) do
          Time.utc(2010, 1, 2, 0, 0, 0, 0)
        end

        it "returns start of the day as date" do
          expect(mongoized).to eq(expected)
        end
      end
    end

    context "when provided an integer" do
      include_context 'using AS time zone'

      let(:integer) do
        time.to_i
      end

      let(:mongoized) do
        Date.mongoize(integer)
      end

      context 'integer in the same local day' do
        let(:time) do
          Time.utc(2010, 1, 1, 2, 3, 4)
        end

        let(:expected) do
          Time.utc(2010, 1, 1, 0, 0, 0, 0)
        end

        it "returns start of the day as date" do
          expect(mongoized).to eq(expected)
        end
      end

      context 'integer in a different local day' do
        let(:time) do
          Time.utc(2010, 1, 1, 22, 3, 4)
        end

        let(:expected) do
          Time.utc(2010, 1, 2, 0, 0, 0, 0)
        end

        it "returns start of the day as date" do
          expect(mongoized).to eq(expected)
        end
      end
    end

    context "when provided a time" do
      include_context 'using AS time zone'

      let(:mongoized) do
        Date.mongoize(time)
      end

      context 'in the same local day' do
        let(:expected) do
          Time.utc(2010, 1, 1, 0, 0, 0)
        end

        let(:time) do
          Time.utc(2010, 1, 1, 22, 3, 4)
        end

        it "returns the date specified in the time without regard for local day" do
          expect(mongoized).to eq(expected)
        end
      end

      context 'in another local day' do
        let(:expected) do
          Time.utc(2010, 1, 1, 0, 0, 0)
        end

        let(:time) do
          Time.utc(2010, 1, 1, 2, 3, 4)
        end

        it "returns the date specified in the time without regard for local day" do
          expect(mongoized).to eq(expected)
        end
      end
    end

    context "when provided an AS::TimeWithZone" do
      include_context 'using AS time zone'

      let(:mongoized) do
        Date.mongoize(time)
      end

      context 'in the same local day' do
        let(:expected) do
          Time.utc(2010, 1, 1, 0, 0, 0)
        end

        let(:time) do
          # Tokyo is +9
          ActiveSupport::TimeZone['PST8PDT'].local(2010, 1, 1, 1, 3, 4)
        end

        it "returns the date specified in the time without regard for local day" do
          expect(mongoized).to eq(expected)
        end
      end

      context 'in another local day' do
        let(:expected) do
          Time.utc(2010, 1, 1, 0, 0, 0)
        end

        let(:time) do
          ActiveSupport::TimeZone['Moscow'].local(2010, 1, 1, 1, 3, 4)
        end

        it "returns the date specified in the time without regard for local day" do
          expect(mongoized).to eq(expected)
        end
      end
    end

    context "when provided a DateTime" do
      include_context 'using AS time zone'

      let(:mongoized) do
        Date.mongoize(date_time)
      end

      context 'in the same local day' do
        let(:expected) do
          Time.utc(2010, 1, 1, 0, 0, 0)
        end

        let(:date_time) do
          # Tokyo is +9
          DateTime.parse('2010-01-01 01:03:04 -0800')
        end

        it "returns the date specified in the time without regard for local day" do
          expect(mongoized).to eq(expected)
        end
      end

      context 'in another local day' do
        let(:expected) do
          Time.utc(2010, 1, 1, 0, 0, 0)
        end

        let(:date_time) do
          DateTime.parse('2010-01-01 01:03:04 +0100')
        end

        it "returns the date specified in the time without regard for local day" do
          expect(mongoized).to eq(expected)
        end
      end
    end

    context "when provided an array" do
      include_context 'using AS time zone'

      let(:expected) do
        Time.utc(2010, 1, 1, 0, 0, 0)
      end

      let(:array) do
        [ 2010, 1, 1, 2, 3, 4, 0 ]
      end

      let(:mongoized) do
        Date.mongoize(array)
      end

      it "returns the array as a time" do
        expect(mongoized).to eq(expected)
      end
    end

    context "when provided nil" do

      it "returns nil" do
        expect(Date.mongoize(nil)).to be_nil
      end
    end
  end
end
