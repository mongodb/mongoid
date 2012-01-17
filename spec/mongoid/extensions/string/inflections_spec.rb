require "spec_helper"

describe Mongoid::Extensions::String::Inflections do

  describe "#collectionize" do

    context "when class is namepaced" do

      it "returns an underscored tableized name" do
        Medical::Patient.name.collectionize.should == "medical_patients"
      end
    end

    context "when class is not namespaced" do

      it "returns an underscored tableized name" do
        MixedDrink.name.collectionize.should == "mixed_drinks"
      end
    end
  end

  describe "#identify" do

    context "when parameterizing composite keys" do

      it "converts the string to all lowercase and dashed" do
        "A Midsummer Night's Dream".identify.should == "a-midsummer-night-quo-s-dream"
      end
    end

    context "when not parameterizing keys" do

      before do
        Mongoid.parameterize_keys = false
      end

      after do
        Mongoid.parameterize_keys = true
      end

      it "does nothing to the keys" do
        "A Midsummer Night's Dream".identify.should == "A Midsummer Night's Dream"
      end
    end
  end

  describe "invert" do

    context "when asc" do

      it "returns desc" do
        "asc".invert.should == "desc"
      end
    end

    context "when ascending" do

      it "returns descending" do
        "ascending".invert.should == "descending"
      end
    end

    context "when desc" do

      it "returns asc" do
        "desc".invert.should == "asc"
      end
    end

    context "when descending" do

      it "returns ascending" do
        "descending".invert.should == "ascending"
      end
    end
  end

  describe "#reader" do

    context "when string is a reader" do

      it "returns self" do
        "attribute".reader.should == "attribute"
      end
    end

    context "when string is a writer" do

      it "returns the reader" do
        "attribute=".reader.should == "attribute"
      end
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

  describe "#singularize" do

    context "when string is address" do

      it "returns address" do
        "address".singularize.should == "address"
      end
    end

    context "when string is address_profiles" do

      it "returns address_profile" do
        "address_profiles".singularize.should == "address_profile"
      end
    end

  end
end
