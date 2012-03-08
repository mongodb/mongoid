require "spec_helper"

describe Mongoid::Extensions::Symbol do

  describe "invert" do

    context "when :asc" do

      it "returns :desc" do
        :asc.invert.should eq(:desc)
      end
    end

    context "when :ascending" do

      it "returns :descending" do
        :ascending.invert.should eq(:descending)
      end
    end

    context "when :desc" do

      it "returns :asc" do
        :desc.invert.should eq(:asc)
      end
    end

    context "when :descending" do

      it "returns :ascending" do
        :descending.invert.should eq(:ascending)
      end
    end
  end

  describe "#mongoid_id?" do

    context "when the string is id" do

      it "returns true" do
        :id.should be_mongoid_id
      end
    end

    context "when the string is _id" do

      it "returns true" do
        :_id.should be_mongoid_id
      end
    end

    context "when the string contains id" do

      it "returns false" do
        :identity.should_not be_mongoid_id
      end
    end

    context "when the string contains _id" do

      it "returns false" do
        :something_id.should_not be_mongoid_id
      end
    end
  end
end
