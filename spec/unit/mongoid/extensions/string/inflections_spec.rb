require "spec_helper"

describe Mongoid::Extensions::String::Inflections do

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
end
