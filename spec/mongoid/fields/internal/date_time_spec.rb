require "spec_helper"

describe Mongoid::Fields::Internal::DateTime do

  let(:field) do
    described_class.instantiate(:test, type: DateTime)
  end

  let!(:time) do
    Time.now.utc
  end

  describe "#cast_on_read?" do

    it "returns true" do
      field.should be_cast_on_read
    end
  end

  describe "#deserialize" do

    let(:date_time) do
      field.deserialize(time)
    end

    it "converts to a datetime" do
      date_time.should be_kind_of(DateTime)
    end

    it "does not change the time" do
      field.deserialize(time).should eq(time)
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

  describe "#serialize" do

    context "when the string is an invalid time" do

      it "raises an error" do
        expect {
          field.serialize("shitty time")
        }.to raise_error(Mongoid::Errors::InvalidTime)
      end
    end
  end
end
