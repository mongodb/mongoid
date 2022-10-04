# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Extensions::Time do

  describe ".demongoize" do

    let!(:time) do
      Time.local(2010, 11, 19)
    end

    context "when the time zone is not defined" do
      config_override :use_utc, false

      context "when the local time is not observing daylight saving" do

        let(:time) do
          Time.utc(2010, 11, 19)
        end

        it "returns the local time" do
          expect(Time.demongoize(time).utc_offset).to eq(
            Time.local(2010, 11, 19).utc_offset
          )
        end
      end

      context "when the local time is observing daylight saving" do

        let(:time) do
          Time.utc(2010, 9, 19)
        end

        it "returns the local time" do
          expect(Time.demongoize(time)).to eq(time.getlocal)
        end
      end

      context "when we have a time close to midnight" do

        let(:time) do
          Time.local(2010, 11, 19, 0, 30).utc
        end

        it "changes it back to the equivalent local time" do
          expect(Time.demongoize(time)).to eq(time)
        end
      end

      context "when using the ActiveSupport time zone" do
        config_override :use_activesupport_time_zone, true
        time_zone_override "Stockholm"

        context "when demongoizing a Time" do

          it "returns an ActiveSupport::TimeWithZone" do
            expect(Time.demongoize(time).class).to eq(ActiveSupport::TimeWithZone)
          end
        end

        context "when demongoizing a Date" do

          it "returns an ActiveSupport::TimeWithZone" do
            expect(Time.demongoize(Date.today).class).to eq(ActiveSupport::TimeWithZone)
          end
        end

        context "when the local time is not observing daylight saving" do

          let(:new_time) do
            Time.utc(2010, 11, 19, 12)
          end

          it "returns the local time" do
            expect(Time.demongoize(new_time)).to eq(
              Time.zone.local(2010, 11, 19, 13)
            )
          end
        end

        context "when the local time is observing daylight saving" do

          let(:new_time) do
            Time.utc(2010, 9, 19, 12)
          end

          it "returns the local time" do
            expect(Time.demongoize(new_time)).to eq(
              Time.zone.local(2010, 9, 19, 14)
            )
          end
        end

        context "when we have a time close to midnight" do

          let(:new_time) do
            Time.utc(2010, 11, 19, 0, 30)
          end

          it "change it back to the equivalent local time" do
            expect(Time.demongoize(new_time)).to eq(
              Time.zone.local(2010, 11, 19, 1, 30)
            )
          end
        end
      end
    end

    context "when the time zone is defined as UTC" do
      config_override :use_utc, true

      it "returns utc" do
        expect(Time.demongoize(time.dup.utc).utc_offset).to eq(0)
      end

      context "when using the ActiveSupport time zone" do
        config_override :use_activesupport_time_zone, true
        time_zone_override "Stockholm"

        let(:time) do
          Time.utc(2010, 11, 19, 0, 30)
        end

        it "returns utc" do
          expect(Time.demongoize(time)).to eq(
            ActiveSupport::TimeZone['UTC'].local(2010, 11, 19, 0, 30)
          )
        end

        it "returns an ActiveSupport::TimeWithZone" do
          expect(Time.demongoize(time).class).to eq(
            ActiveSupport::TimeWithZone
          )
        end
      end
    end

    context "when time is nil" do

      it "returns nil" do
        expect(Time.demongoize(nil)).to be_nil
      end
    end

    context "when the value is uncastable" do

      it "returns nil" do
        expect(Time.demongoize("bogus")).to be_nil
      end
    end

    context "when the value is a string" do

      context "when use_utc is false" do
        config_override :use_utc, false

        context "when using active support's time zone" do
          include_context 'using AS time zone'

          context "when the string is a valid time with time zone" do

            let(:string) do
              # JST is +0900
              "2010-11-19 00:24:49.123457 +1100"
            end

            let(:mongoized) do
              Time.demongoize(string)
            end

            let(:expected_time) { Time.parse("2010-11-18 13:24:49.123457 +0000").in_time_zone }

            it "converts to the AS time zone" do
              expect(mongoized.zone).to eq("JST")
            end

            it_behaves_like 'mongoizes to AS::TimeWithZone'
            it_behaves_like 'maintains precision when mongoized'
          end

          context "when the string is a valid time without time zone" do

            let(:string) do
              "2010-11-19 00:24:49.123457"
            end

            let(:mongoized) do
              Time.demongoize(string)
            end

            let(:expected_time) { Time.parse("2010-11-18 15:24:49.123457 +0000").in_time_zone }

            it "converts to the AS time zone" do
              expect(mongoized.zone).to eq("JST")
            end

            it_behaves_like 'mongoizes to AS::TimeWithZone'
            it_behaves_like 'maintains precision when mongoized'
          end

          context "when the string is a valid time without time" do

            let(:string) do
              "2010-11-19"
            end

            let(:mongoized) do
              Time.demongoize(string)
            end

            let(:expected_time) { Time.parse("2010-11-18 15:00:00 +0000").in_time_zone }

            it "converts to the AS time zone" do
              expect(mongoized.zone).to eq("JST")
            end

            it_behaves_like 'mongoizes to AS::TimeWithZone'
          end

          context "when the string is an invalid time" do

            let(:string) do
              "bogus"
            end

            it "returns nil" do
              expect(Time.demongoize(string)).to be_nil
            end
          end
        end

        context "when not using active support's time zone" do
          include_context 'not using AS time zone'

          context "when the string is a valid time with time zone" do

            let(:string) do
              "2010-11-19 00:24:49.123457 +1100"
            end

            let(:expected_time) { Time.parse("2010-11-18 13:24:49.123457 +0000").in_time_zone }

            let(:mongoized) do
              Time.demongoize(string)
            end

            it_behaves_like 'mongoizes to Time'
            it_behaves_like 'maintains precision when mongoized'
          end

          context "when the string is a valid time without time zone" do

            let(:string) do
              "2010-11-19 00:24:49.123457"
            end

            let(:utc_offset) do
              Time.now.utc_offset
            end

            let(:expected_time) { Time.parse("2010-11-19 00:24:49.123457 +0000") - Time.parse(string).utc_offset }

            let(:mongoized) do
              Time.demongoize(string)
            end

            it 'test operates in multiple time zones' do
              expect(utc_offset).not_to eq(Time.zone.now.utc_offset)
            end

            it_behaves_like 'mongoizes to Time'
            it_behaves_like 'maintains precision when mongoized'
          end

          context "when the string is a valid time without time" do

            let(:string) do
              "2010-11-19"
            end

            let(:mongoized) do
              Time.demongoize(string)
            end

            let(:utc_offset) do
              Time.now.utc_offset
            end

            let(:expected_time) { Time.parse("2010-11-19 00:00:00 +0000") - Time.parse(string).utc_offset }

            it 'test operates in multiple time zones' do
              expect(utc_offset).not_to eq(Time.zone.now.utc_offset)
            end

            it_behaves_like 'mongoizes to Time'
          end

          context "when the string is an invalid time" do

            let(:string) do
              "bogus"
            end

            it "returns nil" do
              expect(Time.demongoize(string)).to be_nil
            end
          end
        end
      end

      context "when use_utc is true" do
        config_override :use_utc, true

        context "when using active support's time zone" do
          include_context 'using AS time zone'

          context "when the string is a valid time with time zone" do

            let(:string) do
              # JST is +0900
              "2010-11-19 00:24:49.123457 +1100"
            end

            let(:mongoized) do
              Time.demongoize(string)
            end

            let(:expected_time) { Time.parse("2010-11-18 13:24:49.123457 +0000").in_time_zone }

            it "converts to UTC" do
              expect(mongoized.zone).to eq("UTC")
            end

            it_behaves_like 'mongoizes to AS::TimeWithZone'
            it_behaves_like 'maintains precision when mongoized'
          end

          context "when the string is a valid time without time zone" do

            let(:string) do
              "2010-11-19 00:24:49.123457"
            end

            let(:mongoized) do
              Time.demongoize(string)
            end

            let(:expected_time) { Time.parse("2010-11-18 15:24:49.123457 +0000").in_time_zone }

            it "converts to UTC" do
              expect(mongoized.zone).to eq("UTC")
            end

            it_behaves_like 'mongoizes to AS::TimeWithZone'
            it_behaves_like 'maintains precision when mongoized'
          end

          context "when the string is a valid time without time" do

            let(:string) do
              "2010-11-19"
            end

            let(:mongoized) do
              Time.demongoize(string)
            end

            let(:expected_time) { Time.parse("2010-11-18 15:00:00 +0000").in_time_zone }

            it "converts to UTC" do
              expect(mongoized.zone).to eq("UTC")
            end

            it_behaves_like 'mongoizes to AS::TimeWithZone'
          end

          context "when the string is an invalid time" do

            let(:string) do
              "bogus"
            end

            it "returns nil" do
              expect(Time.demongoize(string)).to be_nil
            end
          end
        end

        context "when not using active support's time zone" do
          include_context 'not using AS time zone'

          context "when the string is a valid time with time zone" do

            let(:string) do
              "2010-11-19 00:24:49.123457 +1100"
            end

            let(:expected_time) { Time.parse("2010-11-18 13:24:49.123457 +0000").in_time_zone }

            let(:mongoized) do
              Time.demongoize(string)
            end

            it_behaves_like 'mongoizes to Time'
            it_behaves_like 'maintains precision when mongoized'
          end

          context "when the string is a valid time without time zone" do

            let(:string) do
              "2010-11-19 00:24:49.123457"
            end

            let(:utc_offset) do
              Time.now.utc_offset
            end

            let(:expected_time) { Time.parse("2010-11-19 00:24:49.123457 +0000") - Time.parse(string).utc_offset }

            let(:mongoized) do
              Time.demongoize(string)
            end

            it 'test operates in multiple time zones' do
              expect(utc_offset).not_to eq(Time.zone.now.utc_offset)
            end

            it_behaves_like 'mongoizes to Time'
            it_behaves_like 'maintains precision when mongoized'
          end

          context "when the string is a valid time without time" do

            let(:string) do
              "2010-11-19"
            end

            let(:mongoized) do
              Time.demongoize(string)
            end

            let(:utc_offset) do
              Time.now.utc_offset
            end

            let(:expected_time) { Time.parse("2010-11-19 00:00:00 +0000") - Time.parse(string).utc_offset }

            it 'test operates in multiple time zones' do
              expect(utc_offset).not_to eq(Time.zone.now.utc_offset)
            end

            it_behaves_like 'mongoizes to Time'
          end

          context "when the string is an invalid time" do

            let(:string) do
              "bogus"
            end

            it "returns nil" do
              expect(Time.demongoize(string)).to be_nil
            end
          end
        end
      end
    end
  end

  describe ".mongoize" do

    let!(:time) do
      Time.local(2010, 11, 19)
    end

    context "when given nil" do

      it "returns nil" do
        expect(Time.mongoize(nil)).to be_nil
      end
    end

    context "when string is empty" do

      let(:mongoized) do
        Time.mongoize("")
      end

      it "returns nil" do
        expect(mongoized).to be_nil
      end
    end

    context "when the value is a string" do

      context "when use_utc is false" do
        config_override :use_utc, false

        context "when using active support's time zone" do
          include_context 'using AS time zone'

          context "when the string is a valid time with time zone" do

            let(:string) do
              # JST is +0900
              "2010-11-19 00:24:49.123457 +1100"
            end

            let(:mongoized) do
              Time.mongoize(string)
            end

            let(:expected_time) { Time.parse("2010-11-18 13:24:49.123457 +0000").in_time_zone }

            it "converts to UTC" do
              expect(mongoized.zone).to eq("UTC")
            end

            it_behaves_like 'maintains precision when mongoized'
          end

          context "when the string is a valid time without time zone" do

            let(:string) do
              "2010-11-19 00:24:49.123457"
            end

            let(:mongoized) do
              Time.mongoize(string)
            end

            let(:expected_time) { Time.parse("2010-11-18 15:24:49.123457 +0000").in_time_zone }

            it "converts to UTC" do
              expect(mongoized.zone).to eq("UTC")
            end

            it_behaves_like 'maintains precision when mongoized'
          end

          context "when the string is a valid time without time" do

            let(:string) do
              "2010-11-19"
            end

            let(:mongoized) do
              Time.mongoize(string)
            end

            let(:expected_time) { Time.parse("2010-11-18 15:00:00 +0000").in_time_zone }

            it "converts to UTC" do
              expect(mongoized.zone).to eq("UTC")
            end
          end

          context "when the string is an invalid time" do

            let(:string) do
              "bogus"
            end

            it "returns nil" do
              expect(Time.mongoize(string)).to be_nil
            end
          end
        end

        context "when not using active support's time zone" do
          include_context 'not using AS time zone'

          context "when the string is a valid time with time zone" do

            let(:string) do
              "2010-11-19 00:24:49.123457 +1100"
            end

            let(:expected_time) { Time.parse("2010-11-18 13:24:49.123457 +0000").in_time_zone }

            let(:mongoized) do
              Time.mongoize(string)
            end

            it_behaves_like 'mongoizes to Time'
            it_behaves_like 'maintains precision when mongoized'
          end

          context "when the string is a valid time without time zone" do

            let(:string) do
              "2010-11-19 00:24:49.123457"
            end

            let(:utc_offset) do
              Time.now.utc_offset
            end

            let(:expected_time) { Time.parse("2010-11-19 00:24:49.123457 +0000") - Time.parse(string).utc_offset }

            let(:mongoized) do
              Time.mongoize(string)
            end

            it 'test operates in multiple time zones' do
              expect(utc_offset).not_to eq(Time.zone.now.utc_offset)
            end

            it_behaves_like 'mongoizes to Time'
            it_behaves_like 'maintains precision when mongoized'
          end

          context "when the string is a valid time without time" do

            let(:string) do
              "2010-11-19"
            end

            let(:mongoized) do
              Time.mongoize(string)
            end

            let(:utc_offset) do
              Time.now.utc_offset
            end

            let(:expected_time) { Time.parse("2010-11-19 00:00:00 +0000") - Time.parse(string).utc_offset }

            it 'test operates in multiple time zones' do
              expect(utc_offset).not_to eq(Time.zone.now.utc_offset)
            end

            it_behaves_like 'mongoizes to Time'
          end

          context "when the string is an invalid time" do

            let(:string) do
              "bogus"
            end

            it "returns nil" do
              expect(Time.mongoize(string)).to be_nil
            end
          end
        end
      end

      context "when use_utc is true" do
        config_override :use_utc, true

        context "when using active support's time zone" do
          include_context 'using AS time zone'

          context "when the string is a valid time with time zone" do

            let(:string) do
              # JST is +0900
              "2010-11-19 00:24:49.123457 +1100"
            end

            let(:mongoized) do
              Time.mongoize(string)
            end

            let(:expected_time) { Time.parse("2010-11-18 13:24:49.123457 +0000").in_time_zone }

            it "converts to UTC" do
              expect(mongoized.zone).to eq("UTC")
            end

            it_behaves_like 'maintains precision when mongoized'
          end

          context "when the string is a valid time without time zone" do

            let(:string) do
              "2010-11-19 00:24:49.123457"
            end

            let(:mongoized) do
              Time.mongoize(string)
            end

            let(:expected_time) { Time.parse("2010-11-18 15:24:49.123457 +0000").in_time_zone }

            it "converts to UTC" do
              expect(mongoized.zone).to eq("UTC")
            end

            it_behaves_like 'maintains precision when mongoized'
          end

          context "when the string is a valid time without time" do

            let(:string) do
              "2010-11-19"
            end

            let(:mongoized) do
              Time.mongoize(string)
            end

            let(:expected_time) { Time.parse("2010-11-18 15:00:00 +0000").in_time_zone }

            it "converts to UTC" do
              expect(mongoized.zone).to eq("UTC")
            end
          end

          context "when the string is an invalid time" do

            let(:string) do
              "bogus"
            end

            it "returns nil" do
              expect(Time.mongoize(string)).to be_nil
            end
          end
        end

        context "when not using active support's time zone" do
          include_context 'not using AS time zone'

          context "when the string is a valid time with time zone" do

            let(:string) do
              "2010-11-19 00:24:49.123457 +1100"
            end

            let(:expected_time) { Time.parse("2010-11-18 13:24:49.123457 +0000").in_time_zone }

            let(:mongoized) do
              Time.mongoize(string)
            end

            it_behaves_like 'mongoizes to Time'
            it_behaves_like 'maintains precision when mongoized'
          end

          context "when the string is a valid time without time zone" do

            let(:string) do
              "2010-11-19 00:24:49.123457"
            end

            let(:utc_offset) do
              Time.now.utc_offset
            end

            let(:expected_time) { Time.parse("2010-11-19 00:24:49.123457 +0000") - Time.parse(string).utc_offset }

            let(:mongoized) do
              Time.mongoize(string)
            end

            it 'test operates in multiple time zones' do
              expect(utc_offset).not_to eq(Time.zone.now.utc_offset)
            end

            it_behaves_like 'mongoizes to Time'
            it_behaves_like 'maintains precision when mongoized'
          end

          context "when the string is a valid time without time" do

            let(:string) do
              "2010-11-19"
            end

            let(:mongoized) do
              Time.mongoize(string)
            end

            let(:utc_offset) do
              Time.now.utc_offset
            end

            let(:expected_time) { Time.parse("2010-11-19 00:00:00 +0000") - Time.parse(string).utc_offset }

            it 'test operates in multiple time zones' do
              expect(utc_offset).not_to eq(Time.zone.now.utc_offset)
            end

            it_behaves_like 'mongoizes to Time'
          end

          context "when the string is an invalid time" do

            let(:string) do
              "bogus"
            end

            it "returns nil" do
              expect(Time.mongoize(string)).to be_nil
            end
          end
        end
      end
    end

    context "when given a DateTime" do

      let!(:time) do
        DateTime.now
      end

      let!(:eom_time) do
        DateTime.parse("2012-11-30T23:59:59.999999999-05:00")
      end

      let!(:eom_time_mongoized) do
        eom_time.mongoize
      end

      it "doesn't strip milli- or microseconds" do
        expect(Time.mongoize(time).to_f).to eq(time.to_time.to_f)
      end

      it "doesn't round up the hour at end of month" do
        expect(eom_time_mongoized.hour).to eq(eom_time.utc.hour)
      end

      it "doesn't round up the minute" do
        expect(eom_time_mongoized.min).to eq(eom_time.utc.min)
      end

      it "doesn't round up the seconds" do
        expect(eom_time_mongoized.sec).to eq(eom_time.utc.sec)
      end

      it "does not alter seconds" do
        expect((eom_time_mongoized.usec)).to eq(999999)
      end

      it "does not alter seconds with fractions" do
        expect(DateTime.mongoize(1.11).to_f).to eq(1.11)
      end

      context "when using the ActiveSupport time zone" do
        config_override :use_activesupport_time_zone, true
        # if this is actually your time zone, the following tests are useless
        time_zone_override "Stockholm"

        let(:datetime) do
          DateTime.new(2010, 11, 19)
        end

        it "assumes the given time is local" do
          expect(Time.mongoize(datetime)).to eq(
            Time.utc(2010, 11, 19)
          )
        end

        it "doesn't round up the hour" do
          expect(eom_time_mongoized.hour).to eq(eom_time.utc.hour)
        end

        it "doesn't round up the minutes" do
          expect(eom_time_mongoized.min).to eq(eom_time.utc.min)
        end

        it "doesn't round up the seconds" do
          expect(eom_time_mongoized.sec).to eq(eom_time.utc.sec)
        end

        it "does not alter the seconds" do
          expect((eom_time_mongoized.usec)).to eq(999999)
        end
      end
    end

    context "when given a Time" do

      it "converts to a utc time" do
        expect(Time.mongoize(time).utc_offset).to eq(0)
      end

      it "returns utc times unchanged" do
        expect(Time.mongoize(time.utc)).to eq(time.utc)
      end

      it "returns the time as utc" do
        expect(Time.mongoize(time)).to eq(time.utc)
      end

      it "doesn't strip milli- or microseconds" do
        expect(Time.mongoize(time).to_f).to eq(time.to_f)
      end

      it "does not alter seconds with fractions" do
        expect(Time.mongoize(102.25).to_f).to eq(102.25)
      end
    end

    context "when given an ActiveSupport::TimeWithZone" do

      before do
        1.hour.ago
      end

      it "converts it to utc" do
        expect(Time.mongoize(time.in_time_zone("Alaska"))).to eq(
          Time.at(time.to_i).utc
        )
      end
    end

    context "when given a Date" do

      let(:date) do
        Date.today
      end

      it "converts to a utc time" do
        expect(Time.mongoize(date)).to eq(Time.local(date.year, date.month, date.day))
      end

      it "has a zero utc offset" do
        expect(Time.mongoize(date).utc_offset).to eq(0)
      end

      context "when using the ActiveSupport time zone" do
        config_override :use_activesupport_time_zone, true
        # if this is actually your time zone, the following tests are useless
        time_zone_override "Stockholm"

        let(:date) do
          Date.new(2010, 11, 19)
        end

        it "assumes the given time is local" do
          expect(Time.mongoize(date)).to eq(Time.utc(2010, 11, 18, 23))
        end
      end
    end

    context "when given an array" do

      let(:array) do
        [ 2010, 11, 19, 00, 24, 49 ]
      end

      it "returns a time" do
        expect(Time.mongoize(array)).to eq(Time.local(*array))
      end

      context "when using the ActiveSupport time zone" do
        config_override :use_activesupport_time_zone, true
        # if this is actually your time zone, the following tests are useless
        time_zone_override "Stockholm"

        it "assumes the given time is local" do
          expect(Time.mongoize(array)).to eq(
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

    let!(:eom_time) do
      Time.local(2012, 11, 30, 23, 59, 59, 999999.999)
    end

    let!(:eom_time_mongoized) do
      eom_time.mongoize
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

    it "doesn't round up at end of month" do
      expect(eom_time_mongoized.hour).to eq(eom_time.utc.hour)
      expect(eom_time_mongoized.min).to eq(eom_time.utc.min)
      expect(eom_time_mongoized.sec).to eq(eom_time.utc.sec)
      expect(eom_time_mongoized.usec).to eq(eom_time.utc.usec)
      expect(eom_time_mongoized.subsec.to_f.round(3)).to eq(eom_time.utc.subsec.to_f.round(3))
    end
  end

  describe "__mongoize_time__" do

    let(:time) do
      Time.at(1543331265.123457)
    end

    let(:mongoized) do
      time.__mongoize_time__
    end

    let(:expected_time) { time.in_time_zone }

    context "when using active support's time zone" do
      include_context 'using AS time zone'

      it_behaves_like 'mongoizes to Time'
      it_behaves_like 'maintains precision when mongoized'
    end

    context "when not using active support's time zone" do
      include_context 'not using AS time zone'

      it_behaves_like 'mongoizes to Time'
      it_behaves_like 'maintains precision when mongoized'
    end
  end
end
