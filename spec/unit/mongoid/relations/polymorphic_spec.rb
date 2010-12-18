require "spec_helper"

describe Mongoid::Relations::Polymorphic do

  describe ".polymorphic?" do

    context "when the document is in a polymorphic relation" do

      it "returns true" do
        Movie.should be_polymorphic
      end
    end

    context "when the document is not in a polymorphic relation" do

      it "returns false" do
        Survey.should_not be_polymorphic
      end
    end
  end

  describe "#polymorphic?" do

    context "when the document is in a polymorphic relation" do

      it "returns true" do
        Movie.new.should be_polymorphic
      end
    end

    context "when the document is not in a polymorphic relation" do

      it "returns false" do
        Survey.new.should_not be_polymorphic
      end
    end
  end
end
