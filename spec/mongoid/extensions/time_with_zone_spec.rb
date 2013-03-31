require "spec_helper"

describe Mongoid::Extensions::TimeWithZone do

  describe ".demongoize" do

    after(:all) do
      Mongoid.use_utc = false
      Mongoid.use_activesupport_time_zone = true
    end

    let!(:time) do
      Time.local(2010, 11, 19)
    end

    context "when the time zone is not defined" do

      before do
        Mongoid.use_utc = false
      end

      context "when the local time is not observing daylight saving" do

        let(:time) do
          Time.utc(2010, 11, 19)
        end

        it "returns the local time" do
          expect(ActiveSupport::TimeWithZone.demongoize(time).utc_offset).to eq(
            Time.local(2010, 11, 19).utc_offset
          )
        end
      end

      context "when the local time is observing daylight saving" do

        let(:time) do
          Time.utc(2010, 9, 19)
        end

        it "returns the local time" do
          expect(ActiveSupport::TimeWithZone.demongoize(time)).to eq(time.getlocal)
        end
      end

      context "when we have a time close to midnight" do

        let(:time) do
          Time.local(2010, 11, 19, 0, 30).utc
        end

        it "changes it back to the equivalent local time" do
          expect(ActiveSupport::TimeWithZone.demongoize(time)).to eq(time)
        end
      end

      context "when using the ActiveSupport time zone" do

        before do
          Mongoid.use_activesupport_time_zone = true
          Time.zone = "Stockholm"
        end

        after do
          Time.zone = nil
          Mongoid.use_activesupport_time_zone = false
        end

        it "returns an ActiveSupport::TimeWithZone" do
          expect(ActiveSupport::TimeWithZone.demongoize(time).class).to eq(ActiveSupport::TimeWithZone)
        end

        context "when the local time is not observing daylight saving" do

          let(:new_time) do
            Time.utc(2010, 11, 19, 12)
          end

          it "returns the local time" do
            expect(ActiveSupport::TimeWithZone.demongoize(new_time)).to eq(
              Time.zone.local(2010, 11, 19, 13)
            )
          end
        end

        context "when the local time is observing daylight saving" do

          let(:new_time) do
            Time.utc(2010, 9, 19, 12)
          end

          it "returns the local time" do
            expect(ActiveSupport::TimeWithZone.demongoize(new_time)).to eq(
              Time.zone.local(2010, 9, 19, 14)
            )
          end
        end

        context "when we have a time close to midnight" do

          let(:new_time) do
            Time.utc(2010, 11, 19, 0, 30)
          end

          it "change it back to the equivalent local time" do
            expect(ActiveSupport::TimeWithZone.demongoize(new_time)).to eq(
              Time.zone.local(2010, 11, 19, 1, 30)
            )
          end
        end
      end
    end

    context "when the time zone is defined as UTC" do

      before do
        Mongoid.use_utc = true
      end

      after do
        Mongoid.use_utc = false
      end

      it "returns utc" do
        expect(ActiveSupport::TimeWithZone.demongoize(time.dup.utc).utc_offset).to eq(0)
      end

      context "when using the ActiveSupport time zone" do

        let(:time) do
          Time.utc(2010, 11, 19, 0, 30)
        end

        before do
          Mongoid.use_activesupport_time_zone = true
          Time.zone = "Stockholm"
        end

        after do
          Time.zone = nil
          Mongoid.use_activesupport_time_zone = false
        end

        it "returns utc" do
          expect(ActiveSupport::TimeWithZone.demongoize(time)).to eq(
            ActiveSupport::TimeZone['UTC'].local(2010, 11, 19, 0, 30)
          )
        end

        it "returns an ActiveSupport::TimeWithZone" do
          expect(ActiveSupport::TimeWithZone.demongoize(time).class).to eq(
            ActiveSupport::TimeWithZone
          )
        end
      end
    end

    context "when time is nil" do

      it "returns nil" do
        expect(ActiveSupport::TimeWithZone.demongoize(nil)).to be_nil
      end
    end
  end

  describe ".mongoize" do

    let!(:time) do
      Time.local(2010, 11, 19)
    end

    context "when given nil" do

      it "returns nil" do
        expect(ActiveSupport::TimeWithZone.mongoize(nil)).to be_nil
      end
    end

    context "when string is empty" do

      it "returns nil" do
        expect(ActiveSupport::TimeWithZone.mongoize("")).to be_nil
      end
    end

    context "when given a string" do

      context "when the string is a valid time" do

        it "converts to a utc time" do
          expect(ActiveSupport::TimeWithZone.mongoize(time.to_s).utc_offset).to eq(0)
        end

        it "serializes with time parsing" do
          expect(ActiveSupport::TimeWithZone.mongoize(time.to_s)).to eq(Time.parse(time.to_s).utc)
        end

        it "returns a local date from the string" do
          expect(ActiveSupport::TimeWithZone.mongoize(time.to_s)).to eq(
            Time.local(time.year, time.month, time.day, time.hour, time.min, time.sec)
          )
        end
      end

      context "when the string is an invalid time" do

        let(:epoch) do
          Time.utc(1970, 1, 1, 0, 0, 0)
        end

        it "returns epoch" do
          expect(ActiveSupport::TimeWithZone.mongoize("time")).to eq(epoch)
        end
      end

      context "when using the ActiveSupport time zone" do

        before do
          Mongoid.use_activesupport_time_zone = true
          # if this is actually your time zone, the following tests are useless
          Time.zone = "Stockholm"
        end

        after do
          Time.zone = nil
          Mongoid.use_activesupport_time_zone = false
        end

        context "when the local time is not observing daylight saving" do

          it "returns the local time" do
            expect(ActiveSupport::TimeWithZone.mongoize('2010-11-19 5:00:00')).to eq(
              Time.utc(2010, 11, 19, 4)
            )
          end
        end

        context "when the local time is observing daylight saving" do

          it "returns the local time" do
            expect(ActiveSupport::TimeWithZone.mongoize('2010-9-19 5:00:00')).to eq(
              Time.utc(2010, 9, 19, 3)
            )
          end
        end
      end
    end

    context "when given a DateTime" do

      let!(:time) do
        Time.now
      end

      it "doesn't strip milli- or microseconds" do
        expect(ActiveSupport::TimeWithZone.mongoize(time).to_f.round(4)).to eq(
          time.to_f.round(4)
        )
      end

      context "when using the ActiveSupport time zone" do

        let(:datetime) do
          DateTime.new(2010, 11, 19)
        end

        before do
          Mongoid.use_activesupport_time_zone = true
          # if this is actually your time zone, the following tests are useless
          Time.zone = "Stockholm"
        end

        after do
          Time.zone = nil
          Mongoid.use_activesupport_time_zone = false
        end

        it "assumes the given time is local" do
          expect(ActiveSupport::TimeWithZone.mongoize(datetime)).to eq(
            Time.utc(2010, 11, 19)
          )
        end
      end
    end

    context "when given a Time" do

      it "converts to a utc time" do
        expect(ActiveSupport::TimeWithZone.mongoize(time).utc_offset).to eq(0)
      end

      it "returns utc times unchanged" do
        expect(ActiveSupport::TimeWithZone.mongoize(time.utc)).to eq(time.utc)
      end

      it "returns the time as utc" do
        expect(ActiveSupport::TimeWithZone.mongoize(time)).to eq(time.utc)
      end

      it "doesn't strip milli- or microseconds" do
        expect(ActiveSupport::TimeWithZone.mongoize(time).to_f).to eq(time.to_f)
      end
    end

    context "when given an ActiveSupport::TimeWithZone" do

      before do
        1.hour.ago
      end

      it "converts it to utc" do
        expect(ActiveSupport::TimeWithZone.mongoize(time.in_time_zone("Alaska"))).to eq(
          Time.at(time.to_i).utc
        )
      end
    end

    context "when given a Date" do

      let(:date) do
        Date.today
      end

      it "converts to a utc time" do
        expect(ActiveSupport::TimeWithZone.mongoize(date)).to eq(Time.local(date.year, date.month, date.day))
      end

      it "has a zero utc offset" do
        expect(ActiveSupport::TimeWithZone.mongoize(date).utc_offset).to eq(0)
      end

      context "when using the ActiveSupport time zone" do

        let(:date) do
          Date.new(2010, 11, 19)
        end

        before do
          Mongoid.use_activesupport_time_zone = true
          # if this is actually your time zone, the following tests are useless
          Time.zone = "Stockholm"
        end

        after do
          Time.zone = nil
          Mongoid.use_activesupport_time_zone = false
        end

        it "assumes the given time is local" do
          expect(ActiveSupport::TimeWithZone.mongoize(date)).to eq(Time.utc(2010, 11, 18, 23))
        end
      end
    end

    context "when given an array" do

      let(:array) do
        [ 2010, 11, 19, 00, 24, 49 ]
      end

      it "returns a time" do
        expect(ActiveSupport::TimeWithZone.mongoize(array)).to eq(Time.local(*array))
      end

      context "when using the ActiveSupport time zone" do

        before do
          Mongoid.use_activesupport_time_zone = true
          # if this is actually your time zone, the following tests are useless
          Time.zone = "Stockholm"
        end

        after do
          Time.zone = nil
          Mongoid.use_activesupport_time_zone = false
        end

        it "assumes the given time is local" do
          expect(ActiveSupport::TimeWithZone.mongoize(array)).to eq(
            Time.utc(2010, 11, 18, 23, 24, 49)
          )
        end
      end
    end
  end

  describe "#mongoize" do

    let!(:time) do
      Time.local(2010, 11, 19)
    end

    it "converts to a utc time" do
      expect(time.mongoize.utc_offset).to eq(0)
    end

    it "returns the time as utc" do
      expect(time.mongoize).to eq(time.utc)
    end

    it "doesn't strip milli- or microseconds" do
      expect(time.mongoize.to_f).to eq(time.to_f)
    end
  end
end
