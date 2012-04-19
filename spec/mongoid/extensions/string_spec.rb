require "spec_helper"

describe Mongoid::Extensions::String do

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
end
