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

    it "converts the string to all lowercase and dashed" do
      "A Midnight Summer Night's Dream".identify.should == "a-midnight-summer-nights-dream"
    end

  end

  describe "#labelize" do

    it "returns the underscored name humanized" do
      MixedDrink.name.labelize.should == "Mixed drink"
    end

  end

  describe "#singular?" do

    context "when singular" do

      it "returns true" do
        "bat".singular?.should be_true
      end

      context "when string is added to inflections" do

        it "returns true" do
          "address".singular?.should be_true
        end

      end

    end

    context "when plural" do

      it "returns false" do
        "bats".singular?.should be_false
      end

      context "when string is added to inflections" do

        it "returns false" do
          "addresses".singular?.should be_false
        end

      end

    end

  end

  describe "plural?" do

    context "when singular" do

      it "returns false" do
        "bat".plural?.should be_false
      end

      context "when string is added to inflections" do

        it "returns false" do
          "address".plural?.should be_false
        end

      end

    end

    context "when plural" do

      it "returns true" do
        "bats".plural?.should be_true
      end

      context "when string is added to inflections" do

        it "returns true" do
          "addresses".plural?.should be_true
        end

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

end
