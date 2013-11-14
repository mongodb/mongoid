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

      before do
        Mongoid.use_activesupport_time_zone = true
        ::Time.zone = "Tokyo"
      end

      after do
        ::Time.zone = "Berlin"
      end

      context "when the string is a valid time" do

        let(:string) do
          "2010-11-19 00:24:49 +0900"
        end

        let(:time) do
          string.__mongoize_time__
        end

        it "converts to a time" do
          expect(time).to eq(Time.configured.parse(string))
        end

        it "converts to the as time zone" do
          expect(time.zone).to eq("JST")
        end
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

      before do
        Mongoid.use_activesupport_time_zone = false
      end

      after do
        Mongoid.use_activesupport_time_zone = true
        Time.zone = nil
      end

      context "when the string is a valid time" do

        let(:string) do
          "2010-11-19 00:24:49 +0900"
        end

        let(:time) do
          string.__mongoize_time__
        end

        it "converts to a time" do
          expect(time).to eq(Time.parse(string))
        end
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

      it "returns an underscored tableized name" do
        expect(Medical::Patient.name.collectionize).to eq("medical_patients")
      end
    end

    context "when class is not namespaced" do

      it "returns an underscored tableized name" do
        expect(MixedDrink.name.collectionize).to eq("mixed_drinks")
      end
    end
  end

  describe ".demongoize" do

    context "when the object is not a string" do

      it "returns the string" do
        expect(String.demongoize(:test)).to eq("test")
      end
    end

    context "when the object is nil" do

      it "returns nil" do
        expect(String.demongoize(nil)).to be_nil
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

  describe ".mongoize" do

    context "when the object is not a string" do

      it "returns the string" do
        expect(String.mongoize(:test)).to eq("test")
      end
    end

    context "when the object is nil" do

      it "returns nil" do
        expect(String.mongoize(nil)).to be_nil
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
        expect("1234").to be_numeric
      end
    end

    context "when string is a float" do

      it "returns true" do
        expect("1234.123").to be_numeric
      end
    end

    context "when the string is has exponents" do

      it "returns true" do
        expect("1234.123123E4").to be_numeric
      end
    end

    context "when the string is non numeric" do

      it "returns false" do
        expect("blah").to_not be_numeric
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
