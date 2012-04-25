require "spec_helper"

describe Mongoid::Extensions::DateTime do

  describe ".demongoize" do

    let!(:time) do
      Time.now.utc
    end

    let(:date_time) do
      DateTime.demongoize(time)
    end

    it "converts to a datetime" do
      date_time.should be_kind_of(DateTime)
    end

    it "does not change the time" do
      DateTime.demongoize(time).should eq(time)
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
          user.last_login.should eq(date)
        end
      end
    end
  end

  describe ".mongoize" do

    context "when the string is an invalid time" do

      before do
        Time.zone = nil
      end

      it "raises an error" do
        expect {
          DateTime.mongoize("shitty time")
        }.to raise_error(Mongoid::Errors::InvalidTime)
      end
    end
  end

  describe "#mongoize" do

    let!(:date_time) do
      Time.now.utc.to_datetime
    end

    context "when the string is an invalid time" do

      it "returns the date time as a time" do
        date_time.mongoize.should be_a(Time)
      end
    end
  end
end
