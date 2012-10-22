require "spec_helper"

describe Mongoid::Extensions::String do

  describe "#__evolve_object_id__" do

    context "when the string is blank" do

      it "returns the empty string" do
        "".__evolve_object_id__.should be_empty
      end
    end

    context "when the string is a legal object id" do

      let(:object_id) do
        Moped::BSON::ObjectId.new
      end

      it "returns the object id" do
        object_id.to_s.__evolve_object_id__.should eq(object_id)
      end
    end

    context "when the string is not a legal object id" do

      let(:string) do
        "testing"
      end

      it "returns the string" do
        string.__evolve_object_id__.should eq(string)
      end
    end
  end

  describe "#__mongoize_object_id__" do

    context "when the string is blank" do

      it "returns nil" do
        "".__mongoize_object_id__.should be_nil
      end
    end

    context "when the string is a legal object id" do

      let(:object_id) do
        Moped::BSON::ObjectId.new
      end

      it "returns the object id" do
        object_id.to_s.__mongoize_object_id__.should eq(object_id)
      end
    end

    context "when the string is not a legal object id" do

      let(:string) do
        "testing"
      end

      it "returns the string" do
        string.__mongoize_object_id__.should eq(string)
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
          time.should eq(Time.parse(string))
        end

        it "converts to the as time zone" do
          time.zone.should eq("JST")
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
          time.should eq(Time.parse(string))
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
        Medical::Patient.name.collectionize.should eq("medical_patients")
      end
    end

    context "when class is not namespaced" do

      it "returns an underscored tableized name" do
        MixedDrink.name.collectionize.should eq("mixed_drinks")
      end
    end
  end

  describe ".demongoize" do

    context "when the object is not a string" do

      it "returns the string" do
        String.demongoize(:test).should eq("test")
      end
    end

    context "when the object is nil" do

      it "returns nil" do
        String.demongoize(nil).should be_nil
      end
    end
  end

  describe "#mongoid_id?" do

    context "when the string is id" do

      it "returns true" do
        "id".should be_mongoid_id
      end
    end

    context "when the string is _id" do

      it "returns true" do
        "_id".should be_mongoid_id
      end
    end

    context "when the string contains id" do

      it "returns false" do
        "identity".should_not be_mongoid_id
      end
    end

    context "when the string contains _id" do

      it "returns false" do
        "something_id".should_not be_mongoid_id
      end
    end
  end

  describe ".mongoize" do

    context "when the object is not a string" do

      it "returns the string" do
        String.mongoize(:test).should eq("test")
      end
    end

    context "when the object is nil" do

      it "returns nil" do
        String.mongoize(nil).should be_nil
      end
    end
  end

  describe "#mongoize" do

    it "returns self" do
      "test".mongoize.should eq("test")
    end
  end

  describe "#reader" do

    context "when string is a reader" do

      it "returns self" do
        "attribute".reader.should eq("attribute")
      end
    end

    context "when string is a writer" do

      it "returns the reader" do
        "attribute=".reader.should eq("attribute")
      end
    end

    context "when the string is before_type_cast" do

      it "returns the reader" do
        "attribute_before_type_cast".reader.should eq("attribute")
      end
    end
  end

  describe "#numeric?" do

    context "when the string is an integer" do

      it "returns true" do
        "1234".should be_numeric
      end
    end

    context "when string is a float" do

      it "returns true" do
        "1234.123".should be_numeric
      end
    end

    context "when the string is has exponents" do

      it "returns true" do
        "1234.123123E4".should be_numeric
      end
    end

    context "when the string is non numeric" do

      it "returns false" do
        "blah".should_not be_numeric
      end
    end
  end

  describe "#singularize" do

    context "when string is address" do

      it "returns address" do
        "address".singularize.should eq("address")
      end
    end

    context "when string is address_profiles" do

      it "returns address_profile" do
        "address_profiles".singularize.should eq("address_profile")
      end
    end
  end

  describe "#to_a" do

    let(:value) do
      "Disintegration is the best album ever!"
    end

    it "returns an array with the string in it" do
      value.to_a.should eq([ value ])
    end
  end

  describe "#writer?" do

    context "when string is a reader" do

      it "returns false" do
        "attribute".writer?.should be_false
      end
    end

    context "when string is a writer" do

      it "returns true" do
        "attribute=".writer?.should be_true
      end
    end
  end

  describe "#before_type_cast?" do

    context "when string is a reader" do

      it "returns false" do
        "attribute".before_type_cast?.should be_false
      end
    end

    context "when string is before_type_cast" do

      it "returns true" do
        "attribute_before_type_cast".before_type_cast?.should be_true
      end
    end
  end

end
