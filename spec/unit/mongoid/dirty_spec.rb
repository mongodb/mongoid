require "spec_helper"

describe Mongoid::Dirty do

  describe "#(attribute)_change" do

  end

  describe "#attribute_changed?" do

    context "when the attribute has changed" do

      before do
        @person = Person.new(:title => "Grand Poobah")
        @person.title = "Captain Obvious"
      end

      it "returns true" do
        @person.attribute_changed?("title").should == true
      end
    end

    context "when the attribute has not changed" do

      before do
        @person = Person.new(:title => "Grand Poobah")
      end

      it "returns false" do
        @person.attribute_changed?("title").should == false
      end
    end
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

    context "when the document has changed" do

      before do
        @person = Person.new(:title => "Grand Poobah")
        @person.title = "Captain Obvious"
      end

      it "returns a hash of changes" do
        @person.changes.should ==
          { "title" => [ "Grand Poobah", "Captain Obvious" ] }
      end
    end

    context "when the document has not changed" do

      before do
        @person = Person.new(:title => "Grand Poobah")
      end

      it "returns an empty hash" do
        @person.changes.should == {}
      end
    end
  end

  describe "#previous_changes" do

    before do
      @person = Person.new(:title => "Grand Poobah")
      @person.title = "Captain Obvious"
    end

    context "when the document has been saved" do

      before do
        @person.collection.expects(:save).returns(true)
        @person.save!
      end

      it "returns the changes before the save" do
        @person.previous_changes["title"].should ==
          [ "Grand Poobah", "Captain Obvious" ]
      end
    end

    context "when the document has not been saved" do

      it "returns an empty hash" do
        @person.previous_changes.should == {}
      end
    end
  end

  describe "#reset_(attribute)!" do

  end
end
