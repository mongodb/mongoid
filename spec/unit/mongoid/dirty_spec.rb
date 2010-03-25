require "spec_helper"

describe Mongoid::Dirty do

  describe "#(attribute)_change" do

  end

  describe "#(attribute)_changed?" do

  end

  describe "#(attribute)_was" do

  end

  describe "#changed" do

    context "when the document has changed" do

      before do
        @person = Person.new(:title => "Grand Poobah")
        @person.title = "Captain Obvious"
      end

      it "returns an array of changed field names" do
        @person.changed.should == [ "title" ]
      end
    end

    context "when the document has not changed" do

      before do
        @person = Person.new(:title => "Grand Poobah")
      end

      it "returns an empty array" do
        @person.changed.should == []
      end
    end
  end

  describe "#changed?" do

    context "when the document has changed" do

      before do
        @person = Person.new(:title => "Grand Poobah")
        @person.title = "Captain Obvious"
      end

      it "returns true" do
        @person.should be_changed
      end
    end

    context "when the document has not changed" do

      before do
        @person = Person.new(:title => "Grand Poobah")
      end

      it "returns false" do
        @person.should_not be_changed
      end
    end
  end

  describe "#changes" do

  end

  describe "#previous_changes" do

  end

  describe "#reset_(attribute)!" do

  end
end
