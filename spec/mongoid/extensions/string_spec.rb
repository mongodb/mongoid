# frozen_string_literal: true

require "spec_helper"

describe Mongoid::Extensions::String do

  describe "#__evolve_object_id__" do

    context "when the string is blank" do

      it "returns the empty string" do
        expect("".__evolve_object_id__).to be_empty
      end
    end

    context "when the string is a legal object id" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      it "returns the object id" do
        expect(object_id.to_s.__evolve_object_id__).to eq(object_id)
      end
    end

    context "when the string is not a legal object id" do

      let(:string) do
        "testing"
      end

      it "returns the string" do
        expect(string.__evolve_object_id__).to eq(string)
      end
    end
  end

  describe "#__mongoize_object_id__" do

    context "when the string is blank" do

      it "returns nil" do
        expect("".__mongoize_object_id__).to be_nil
      end
    end

    context "when the string is a legal object id" do

      let(:object_id) do
        BSON::ObjectId.new
      end

      it "returns the object id" do
        expect(object_id.to_s.__mongoize_object_id__).to eq(object_id)
      end
    end

    context "when the string is not a legal object id" do

      let(:string) do
        "testing"
      end

      it "returns the string" do
        expect(string.__mongoize_object_id__).to eq(string)
      end
    end
  end

  describe "#__mongoize_time__" do

    context "when using active support's time zone" do
      include_context 'using AS time zone'

      context "when the string is a valid time with time zone" do

        let(:string) do
          # JST is +0900
          "2010-11-19 00:24:49.123457 +1100"
        end

        let(:mongoized) do
          string.__mongoize_time__
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
          string.__mongoize_time__
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
          string.__mongoize_time__
        end

        let(:expected_time) { Time.parse("2010-11-18 15:00:00 +0000").in_time_zone }

        it "converts to the AS time zone" do
          expect(mongoized.zone).to eq("JST")
        end

        it_behaves_like 'mongoizes to AS::TimeWithZone'
      end

      context "when the string is an invalid time" do

        let(:string) do
          "shitty string"
        end

        it "raises an error" do
          expect {
            string.__mongoize_time__
          }.to raise_error(ArgumentError)
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
          string.__mongoize_time__
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
          string.__mongoize_time__
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
          string.__mongoize_time__
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
          "shitty string"
        end

        it "raises an error" do
          expect {
            string.__mongoize_time__
          }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe "#collectionize" do

    context "when class is namepaced" do

      module Medical
        class Patient
          include Mongoid::Document
        end
      end

      it "returns an underscored table-ized name" do
        expect(Medical::Patient.name.collectionize).to eq("medical_patients")
      end
    end

    context "when class is not namespaced" do

      it "returns an underscored table-ized name" do
        expect(MixedDrink.name.collectionize).to eq("mixed_drinks")
      end
    end
  end

  describe "#mongoid_id?" do

    context "when the string is id" do

      it "returns true" do
        expect("id").to be_mongoid_id
      end
    end

    context "when the string is _id" do

      it "returns true" do
        expect("_id").to be_mongoid_id
      end
    end

    context "when the string contains id" do

      it "returns false" do
        expect("identity").to_not be_mongoid_id
      end
    end

    context "when the string contains _id" do

      it "returns false" do
        expect("something_id").to_not be_mongoid_id
      end
    end
  end

  [ :mongoize, :demongoize ].each do |method|

    describe ".#{method}" do

      context "when the object is not a string" do

        it "returns the string" do
          expect(String.send(method, :test)).to eq("test")
        end
      end

      context "when the object is nil" do

        it "returns nil" do
          expect(String.send(method, nil)).to be_nil
        end
      end
    end
  end

  describe "#mongoize" do

    it "returns self" do
      expect("test".mongoize).to eq("test")
    end
  end

  describe "#reader" do

    context "when string is a reader" do

      it "returns self" do
        expect("attribute".reader).to eq("attribute")
      end
    end

    context "when string is a writer" do

      it "returns the reader" do
        expect("attribute=".reader).to eq("attribute")
      end
    end

    context "when the string is before_type_cast" do

      it "returns the reader" do
        expect("attribute_before_type_cast".reader).to eq("attribute")
      end
    end
  end

  describe "#numeric?" do

    context "when the string is an integer" do

      it "returns true" do
        expect("1234".numeric?).to eq(true)
      end
    end

    context "when string is a float" do

      it "returns true" do
        expect("1234.123".numeric?).to eq(true)
      end
    end

    context "when the string is has exponents" do

      it "returns true" do
        expect("1234.123123E4".numeric?).to eq(true)
      end
    end

    context "when the string is non numeric" do

      it "returns false" do
        expect("blah".numeric?).to eq(false)
      end
    end

    context "when the string is NaN" do

      it "returns true" do
        expect("NaN".numeric?).to eq(true)
      end
    end

    context "when the string is NaN and junk in front" do

      it "returns false" do
        expect("a\nNaN".numeric?).to eq(false)
      end
    end

    context "when the string is NaN and whitespace at end" do

      it "returns false" do
        expect("NaN\n".numeric?).to eq(false)
      end
    end

    context "when the string is Infinity" do

      it "returns true" do
        expect("Infinity".numeric?).to eq(true)
      end
    end

    context "when the string contains Infinity and junk in front" do

      it "returns false" do
        expect("a\nInfinity".numeric?).to eq(false)
      end
    end

    context "when the string contains Infinity and whitespace at end" do

      it "returns false" do
        expect("Infinity\n".numeric?).to eq(false)
      end
    end

    context "when the string is -Infinity" do

      it "returns true" do
        expect("-Infinity".numeric?).to eq(true)
      end
    end
  end

  describe "#singularize" do

    context "when string is address" do

      it "returns address" do
        expect("address".singularize).to eq("address")
      end
    end

    context "when string is address_profiles" do

      it "returns address_profile" do
        expect("address_profiles".singularize).to eq("address_profile")
      end
    end
  end

  describe "#writer?" do

    context "when string is a reader" do

      it "returns false" do
        expect("attribute".writer?).to be false
      end
    end

    context "when string is a writer" do

      it "returns true" do
        expect("attribute=".writer?).to be true
      end
    end
  end

  describe "#before_type_cast?" do

    context "when string is a reader" do

      it "returns false" do
        expect("attribute".before_type_cast?).to be false
      end
    end

    context "when string is before_type_cast" do

      it "returns true" do
        expect("attribute_before_type_cast".before_type_cast?).to be true
      end
    end
  end

end
